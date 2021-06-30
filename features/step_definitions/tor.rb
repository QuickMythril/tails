def iptables_chains_parse(iptables, table = 'filter')
  assert(block_given?)
  cmd = "#{iptables}-save -c -t #{table} | iptables-xml"
  xml_str = $vm.execute_successfully(cmd).stdout
  rexml = REXML::Document.new(xml_str)
  rexml.get_elements('iptables-rules/table/chain').each do |element|
    yield(
      element.attribute('name').to_s,
      element.attribute('policy').to_s,
      element.get_elements('rule')
    )
  end
end

def ip4tables_chains(table = 'filter', &block)
  iptables_chains_parse('iptables', table, &block)
end

def ip6tables_chains(table = 'filter', &block)
  iptables_chains_parse('ip6tables', table, &block)
end

def iptables_rules_parse(iptables, chain, table)
  iptables_chains_parse(iptables, table) do |name, _, rules|
    return rules if name == chain
  end
  nil
end

def iptables_rules(chain, table = 'filter')
  iptables_rules_parse('iptables', chain, table)
end

def ip6tables_rules(chain, table = 'filter')
  iptables_rules_parse('ip6tables', chain, table)
end

def ip4tables_packet_counter_sum(**filters)
  pkts = 0
  ip4tables_chains do |name, _, rules|
    next if filters[:tables] && !filters[:tables].include?(name)

    rules.each do |rule|
      if filters[:uid] &&
         !rule.elements["conditions/owner/uid-owner[text()=#{filters[:uid]}]"]
        next
      end

      pkts += rule.attribute('packet-count').to_s.to_i
    end
  end
  pkts
end

def try_xml_element_text(element, xpath, default = nil)
  node = element.elements[xpath]
  node.nil? || !node.has_text? ? default : node.text
end

Then /^the firewall's policy is to (.+) all IPv4 traffic$/ do |expected_policy|
  expected_policy.upcase!
  ip4tables_chains do |name, policy, _|
    if ['INPUT', 'FORWARD', 'OUTPUT'].include?(name)
      assert_equal(expected_policy, policy,
                   "Chain #{name} has unexpected policy #{policy}")
    end
  end
end

Then /^the firewall is configured to only allow the (.+) users? to connect directly to the Internet over IPv4$/ do |users_str|
  users = users_str.split(/, | and /)
  expected_uids = Set.new
  users.each do |user|
    expected_uids << $vm.execute_successfully("id -u #{user}").stdout.to_i
  end
  allowed_output = iptables_rules('OUTPUT').select do |rule|
    out_iface = rule.elements['conditions/match/o']
    is_maybe_accepted = rule.get_elements('actions/*').find do |action|
      !['DROP', 'REJECT', 'LOG'].include?(action.name)
    end
    is_maybe_accepted &&
      (
        # nil => match all interfaces according to iptables-xml
        out_iface.nil? ||
        ((out_iface.text == 'lo') \
         == \
         (out_iface.attribute('invert').to_s == '1'))
      )
  end
  uids = Set.new
  allowed_output.each do |rule|
    rule.elements.each('actions/*') do |action|
      destination = try_xml_element_text(rule, 'conditions/match/d')
      if action.name == 'ACCEPT'
        # nil == 0.0.0.0/0 according to iptables-xml
        assert(destination == '0.0.0.0/0' || destination.nil?,
               "The following rule has an unexpected destination:\n" +
               rule.to_s)
        state_cond = try_xml_element_text(rule, 'conditions/state/state')
        next if state_cond == 'ESTABLISHED'

        assert_not_nil(rule.elements['conditions/owner/uid-owner'])
        rule.elements.each('conditions/owner/uid-owner') do |owner|
          uid = owner.text.to_i
          uids << uid
          assert(expected_uids.include?(uid),
                 "The following rule allows uid #{uid} to access the " \
                 "network, but we only expect uids #{expected_uids.to_a} " \
                 "(#{users_str}) to have such access:\n#{rule}")
        end
      elsif action.name == 'call' && action.elements[1].name == 'lan'
        lan_subnets = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']
        assert(lan_subnets.include?(destination),
               "The following lan-targeted rule's destination is " \
               "#{destination} which may not be a private subnet:\n" +
               rule.to_s)
      else
        raise "Unexpected iptables OUTPUT chain rule:\n#{rule}"
      end
    end
  end
  uids_not_found = expected_uids - uids
  assert(uids_not_found.empty?,
         "Couldn't find rules allowing uids #{uids_not_found.to_a} " \
         'access to the network')
end

Then /^the firewall's NAT rules only redirect traffic for Tor's TransPort and DNSPort$/ do
  loopback_address = '127.0.0.1/32'
  tor_onion_addr_space = '127.192.0.0/10'
  tor_trans_port = '9040'
  dns_port = '53'
  tor_dns_port = '5353'
  ip4tables_chains('nat') do |name, _, rules|
    if name == 'OUTPUT'
      good_rules = rules.select do |rule|
        redirect = rule.get_elements('actions/*').all? do |action|
          action.name == 'REDIRECT'
        end
        destination = try_xml_element_text(rule, 'conditions/match/d')
        redir_port = try_xml_element_text(rule, 'actions/REDIRECT/to-ports')
        redirected_to_trans_port = redir_port == tor_trans_port
        udp_destination_port = try_xml_element_text(rule,
                                                    'conditions/udp/dport')
        dns_redirected_to_tor_dns_port = (udp_destination_port == dns_port) &&
                                         (redir_port == tor_dns_port)
        redirect &&
          (
           (destination == tor_onion_addr_space && redirected_to_trans_port) ||
           (destination == loopback_address && dns_redirected_to_tor_dns_port)
         )
      end
      bad_rules = rules - good_rules
      assert(bad_rules.empty?,
             "The NAT table's OUTPUT chain contains some unexpected " \
             "rules:\n#{bad_rules}")
    else
      assert(rules.empty?,
             "The NAT table contains unexpected rules for the #{name} " \
             "chain:\n#{rules}")
    end
  end
end

Then /^the firewall is configured to block all external IPv6 traffic$/ do
  ip6_loopback = '::1/128'
  expected_policy = 'DROP'
  ip6tables_chains do |name, policy, rules|
    assert_equal(expected_policy, policy,
                 "The IPv6 #{name} chain has policy #{policy} but we " \
                 "expected #{expected_policy}")
    good_rules = rules.select do |rule|
      ['DROP', 'REJECT', 'LOG'].any? do |target|
        rule.elements["actions/#{target}"]
      end \
      ||
        ['s', 'd'].all? do |x|
          try_xml_element_text(rule, "conditions/match/#{x}") == ip6_loopback
        end
    end
    bad_rules = rules - good_rules
    assert(bad_rules.empty?,
           "The IPv6 table's #{name} chain contains some unexpected rules:\n" +
           bad_rules.map(&:to_s).join("\n"))
  end
end

def firewall_has_dropped_packet_to?(proto, host, port)
  regex = '^Dropped outbound packet: .* '
  regex += "DST=#{Regexp.escape(host)} .* "
  regex += "PROTO=#{Regexp.escape(proto)} "
  regex += ".* DPT=#{port} " if port
  $vm.execute("journalctl --dmesg --output=cat | grep -qP '#{regex}'").success?
end

When /^I open an untorified (TCP|UDP|ICMP) connection to (\S*)(?: on port (\d+))?$/ do |proto, host, port|
  assert(!firewall_has_dropped_packet_to?(proto, host, port),
         "A #{proto} packet to #{host}" +
         (port.nil? ? '' : ":#{port}") +
         ' has already been dropped by the firewall')
  @conn_proto = proto
  @conn_host = host
  @conn_port = port
  case proto
  when 'TCP'
    assert_not_nil(port)
    cmd = "echo | nc.traditional #{host} #{port}"
    user = LIVE_USER
  when 'UDP'
    assert_not_nil(port)
    cmd = "echo | nc.traditional -u #{host} #{port}"
    user = LIVE_USER
  when 'ICMP'
    cmd = "ping -c 5 #{host}"
    user = 'root'
  end
  @conn_res = $vm.execute(cmd, user: user)
end

Then /^the untorified connection fails$/ do
  case @conn_proto
  when 'TCP'
    expected_in_stderr = 'Connection refused'
    conn_failed = !@conn_res.success? &&
                  @conn_res.stderr.chomp.end_with?(expected_in_stderr)
  when 'UDP', 'ICMP'
    conn_failed = !@conn_res.success?
  end
  assert(conn_failed,
         "The untorified #{@conn_proto} connection didn't fail as expected:\n" +
         @conn_res.to_s)
end

Then /^the untorified connection is logged as dropped by the firewall$/ do
  assert(firewall_has_dropped_packet_to?(@conn_proto, @conn_host, @conn_port),
         "No #{@conn_proto} packet to #{@conn_host}" +
         (@conn_port.nil? ? '' : ":#{@conn_port}") +
         ' was dropped by the firewall')
end

When /^the system DNS is(?: still)? using the local DNS resolver$/ do
  resolvconf = $vm.file_content('/etc/resolv.conf')
  bad_lines = resolvconf.split("\n").select do |line|
    !line.start_with?('#') && !/^nameserver\s+127\.0\.0\.1$/.match(line)
  end
  assert_empty(bad_lines,
               "The following bad lines were found in /etc/resolv.conf:\n" +
               bad_lines.join("\n"))
end

STREAM_ISOLATION_INFO = {
  'htpdate'                        => {
    grep_monitor_expr: 'users:(("curl"',
    socksport:         9062,
    # htpdate is resolving names through the system resolver, not through socksport
    # (in order to have better error messages). Let it connect to local DNS!
    dns:           true,
  },
  'tails-security-check'           => {
    grep_monitor_expr: 'users:(("tails-security-"',
    socksport:         9062,
  },
  'tails-upgrade-frontend-wrapper' => {
    grep_monitor_expr: 'users:(("tails-iuk-get-u"',
    socksport:         9062,
  },
  'Tor Browser'                    => {
    grep_monitor_expr: 'users:(("firefox\.real"',
    socksport:         9050,
    controller:        true,
    netns:             'tbb',
  },
  'SSH'                            => {
    grep_monitor_expr: 'users:(("\(nc\|ssh\)"',
    socksport:         9050,
  },
}.freeze

def stream_isolation_info(application)
  STREAM_ISOLATION_INFO[application] || \
    raise("Unknown application '#{application}' for the stream isolation tests")
end

When /^I monitor the network connections of (.*)$/ do |application|
  @process_monitor_log = '/tmp/ss.log'
  info = stream_isolation_info(application)
  netns_wrapper = info[:netns].nil? ? '' : "ip netns exec #{info[:netns]}"
  $vm.spawn('while true; do ' \
            "  #{netns_wrapper} ss -taupen " \
            "    | grep '#{info[:grep_monitor_expr]}'; " \
            '  sleep 0.1; ' \
            "done > #{@process_monitor_log}")
end

Then /^I see that (.+) is properly stream isolated(?: after (\d+) seconds)?$/ do |application, delay|
  sleep delay.to_i if delay
  info = stream_isolation_info(application)
  expected_ports = [info[:socksport]]
  expected_ports << 9051 if info[:controller]
  expected_ports << 53 if info[:dns]
  assert_not_nil(@process_monitor_log)
  log_lines = $vm.file_content(@process_monitor_log).split("\n")
  assert(!log_lines.empty?,
         "Couldn't see any connection made by #{application} so " \
         'something is wrong')
  log_lines.each do |line|
    ip_port = line.split(/\s+/)[5]
    assert(expected_ports.map { |port| "127.0.0.1:#{port}" }.include?(ip_port),
           "#{application} should only connect to #{expected_ports} but " \
           "was seen connecting to #{ip_port}")
  end
end

And /^I re-run tails-security-check$/ do
  $vm.execute_successfully(
    'systemctl --user restart tails-security-check.service',
    user: LIVE_USER
  )
end

And /^I re-run htpdate$/ do
  $vm.execute_successfully('service htpdate stop && ' \
                           'rm -f /run/htpdate/* && ' \
                           'systemctl --no-block start htpdate.service')
  step 'the time has synced'
end

And /^I re-run tails-upgrade-frontend-wrapper$/ do
  $vm.execute_successfully('tails-upgrade-frontend-wrapper', user: LIVE_USER)
end

# Note about the "basic" Tor Connection Assistant steps: we have tests which will
# start Tor Connection Assistant (and connect directly to the Tor Network) in
# other languages, so we need to make those steps
# language-agnostic. Unfortunately this means interaction based on
# images is not suitable, so we try more general approaches.

When /^the Tor Connection Assistant (?:autostarts|is running)$/ do
  begin
    try_for(60) do
      tor_connection_assistant
    end
  rescue Timeout::Error
    raise TorBootstrapFailure, 'TCA did not start'
  end
end

def tor_connection_assistant
  Dogtail::Application.new('Tor Connection', translation_domain: 'tails')
end

class TCAConnectionFailure < TorBootstrapFailure
end

def tca_configure(mode, &block)
  step 'the Tor Connection Assistant is running'
  case mode
  when :easy
    radio_button_label = 'Connect to Tor automatically (easier)'
  when :hide
    radio_button_label = "Hide to my local network that I'm connecting to Tor (safer)"
  else
    raise "bad TCA configuration mode '#{mode}'"
  end
  # XXX: We generally run this right after TCA has started, apparently
  # so early that clicking the radio button doesn't always work, so we
  # retry. Can this be fixed in TCA instead some how?
  radio_button = tor_connection_assistant.child(
    radio_button_label, roleName: 'radio button'
  )
  try_for(10) do
    radio_button.click
    radio_button.checked
  end
  block.call if block_given?
  tor_connection_assistant.child('Connect to _Tor', roleName: 'push button')
                          .click
  failure_reported = false
  try_for(120, msg: 'Timed out while waiting for TCA to connect to Tor') do
    if tor_connection_assistant.child?('Error connecting to Tor',
                                       roleName: 'label', retry: false)
      failure_reported = true
      done = true
    else
      done = tor_connection_assistant.child?(
        'Connected to Tor successfully', roleName: 'label', retry: false, showingOnly: true
      )
    end
    done
  end
  if failure_reported
    raise TCAConnectionFailure, 'TCA failed to connect to Tor'
  end
  # XXX: we're so fast closing TCA here that it's done before it
  # issues the SAVECONF, but seemingly only for the "DisableNetwork=0"
  # part, resulting in a lot of breakage. Ideally we would fix this in
  # TCA itself, since a user could be this fast too, theoretically.
  try_for(10, msg: 'DisableNetwork is still set in torrc') do
    $vm.execute('grep "DisableNetwork 1" /etc/tor/torrc').failure?
  end
  @screen.press('alt', 'F4')
end

When /^I configure a direct connection in the Tor Connection Assistant$/ do
  tca_configure(:easy)
end

def chutney_bridge_lines(bridge_type, chutney_tag: nil)
  chutney_tag = bridge_type if chutney_tag.nil?
  bridge_dirs = Dir.glob(
    "#{$config['TMPDIR']}/chutney-data/nodes/*#{chutney_tag}/"
  )
  assert(bridge_dirs.size > 0, "No bridges of type '#{chutney_tag}' found")
  bridge_dirs.map do |bridge_dir|
    address = $vmnet.bridge_ip_addr
    port = nil
    fingerprint = nil
    extra = nil
    if bridge_type == 'bridge'
      File.open("#{bridge_dir}/torrc") do |f|
        port = f.grep(/^OrPort\b/).first.split.last
      end
    else
      # This is the pluggable transport case. While we could set a
      # static port via ServerTransportListenAddr we instead let it be
      # picked randomly so an already used port is not picked --
      # Chutney already has issues with that for OrPort selection.
      pt_re = /Registered server transport '#{bridge_type}' at '[^']*:(\d+)'/
      File.open(bridge_dir + '/notice.log') do |f|
        pt_lines = f.grep(pt_re)
        port = pt_lines.last.match(pt_re)[1]
      end
      if bridge_type == 'obfs4'
        File.open(bridge_dir + '/pt_state/obfs4_bridgeline.txt') do |f|
          extra = f.readlines.last.chomp.sub(/^.* cert=/, 'cert=')
        end
      end
    end
    File.open(bridge_dir + '/fingerprint') do |f|
      fingerprint = f.read.chomp.split.last
    end
    bridge_line = bridge_type + ' ' + address + ':' + port
    [fingerprint, extra].each { |e| bridge_line += ' ' + e.to_s if e }
    bridge_line
  end
end

When /^I configure some (\w+) bridges in the Tor Connection Assistant$/ do |bridge_type|
  @tor_is_using_pluggable_transports = bridge_type != 'normal'
  config_mode = bridge_type == 'normal' ? :easy : :hide
  # Internally a "normal" bridge is called just "bridge" which we have
  # to respect below.
  bridge_type = 'bridge' if bridge_type == 'normal'

  bridge_lines = []
  @bridge_hosts = []
  chutney_bridge_lines(bridge_type).each do |bridge_line|
    bridge_lines << bridge_line
    address, port = bridge_line.split[1].split(":")
    @bridge_hosts << { address: address, port: port.to_i }
  end

  tca_configure(config_mode) do
    if config_mode == :easy
      tor_connection_assistant.child('Configure a Tor bridge',
                                     roleName: 'check box')
                              .click
    end
    tor_connection_assistant.child('Connect to _Tor',
                                   roleName: 'push button')
                            .click
    tor_connection_assistant.child('Type in a bridge that I already know',
                                 roleName: 'radio button')
                            .click
    tor_connection_assistant.child(roleName: 'scroll pane').click

    bridge_lines.each do |bridge_line|
      @screen.type(bridge_line, ['Return'])
    end
  end
end

When /^I try to configure a direct connection in the Tor Connection Assistant$/ do
  begin
    step "I configure a direct connection in the Tor Connection Assistant"
  rescue TCAConnectionFailure
    # Expected!
    next
  rescue StandardError => e
    raise "Expected TCAConnectionFailure to be raised but got " \
          "#{e.class.name}: #{e}"
  else
    raise "TCA managed to connect to Tor but was expected to fail"
  end
end

When /^I close the Tor Connection Assistant$/ do
  $vm.execute(
    'pkill -f /usr/lib/python3/dist-packages/tca/application.py'
  )
end

Then /^the Tor Connection Assistant reports that it failed to connect$/ do
  tor_connection_assistant.child('Error connecting to Tor', roleName: 'label')
end

When /^all Internet traffic has only flowed through the configured bridges$/ do
  assert_not_nil(@bridge_hosts, 'No bridges has been configured via the ' \
                 "'I configure some ... bridges in the Tor Connection Assistant' step")
  assert_all_connections(@sniffer.pcap_file) do |c|
    @bridge_hosts.include?({ address: c.daddr, port: c.dport })
  end
end

Given /^the Tor network( and default bridges)? (?:is|are) (un)?blocked$/ do |default_bridges, unblock|
  relay_dirs = Dir.glob(
    "#{$config['TMPDIR']}/chutney-data/nodes/*{auth,ba,relay}/"
  )
  relays = relay_dirs.map do |relay_dir|
    File.open("#{relay_dir}/torrc") do |f|
      torrc = f.readlines
      [
        torrc.grep(/^Address\b/).first.split.last,
        torrc.grep(/^OrPort\b/).first.split.last
      ]
    end
  end
  if default_bridges
    chutney_bridge_lines('obfs4', chutney_tag: 'defbr').each do |bridge_line|
      relays << bridge_line.split[1].split(":")
    end
  end
  relays.each do |address, port|
    $vm.execute_successfully("iptables -#{unblock ? 'D' : 'I'} OUTPUT " \
                             '-p tcp ' \
                             "--destination #{address} " \
                             "--destination-port #{port} " \
                             '-j REJECT --reject-with icmp-port-unreachable')
  end
end

Then /^Tor is configured to use the default bridges$/ do
  use_bridges = $vm.execute_successfully(
    'tor_control_getconf UseBridges', libs: 'tor'
  ).stdout.chomp.to_i
  assert_equal(1, use_bridges, 'UseBridges is not set')
  default_bridges = $vm.execute_successfully(
    'grep ^obfs4 /usr/share/tails/tca/default_bridges.txt | sort'
  ).stdout.chomp
  assert(default_bridges.size > 0, 'No default bridges were found')
  current_bridges = $vm.execute_successfully(
    'tor_control_getconf Bridge | sort', libs: 'tor'
  ).stdout.chomp
  assert_equal(default_bridges, current_bridges,
               'Current bridges does not match the default ones')
end

When /^I set (.*)=(.*) over Tor's control port$/ do |key, val|
  current_bridges = $vm.execute_successfully(
    "tor_control_setconf '#{key}=#{val}'", libs: 'tor'
  )
end
