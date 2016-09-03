def icedove_app
  Dogtail::Application.new('Icedove')
end

def icedove_main
  # The main window title depends on context so without regexes it
  # will be hard to find it, but it so happens that it is always the
  # first frame of Icedove, so we do not have to be specific.
  icedove_app.child(roleName: 'frame')
end

def icedove_wizard
  icedove_app.child('Mail Account Setup', roleName: 'frame')
end

Then /^Icedove has started$/ do
  icedove_main.wait(60)
end

When /^I have not configured an email account$/ do
  icedove_prefs = $vm.file_content("/home/#{LIVE_USER}/.icedove/profile.default/prefs.js").chomp
  assert(!icedove_prefs.include?('mail.accountmanager.accounts'))
end

Then /^I am prompted to setup an email account$/ do
  icedove_wizard.wait(30)
end

Then /^I cancel setting up an email account$/ do
  icedove_wizard.button('Cancel').click
end

Then /^I open Icedove's Add-ons Manager$/ do
  icedove_main.button('AppMenu').click
  icedove_main.child('Add-ons', roleName: 'menu item').click
  @icedove_addons = icedove_app.child(
    'Add-ons Manager - Icedove Mail/News', roleName: 'frame'
  )
  @icedove_addons.wait
end

Then /^I click the extensions tab$/ do
  @icedove_addons.child('Extensions', roleName: 'list item').click
end

Then /^I see that only the (.+) addons are enabled in Icedove$/ do |addons|
  expected_addons = addons.split(/, | and /)
  actual_addons =
    @icedove_addons.child('amnesia branding', roleName: 'label')
    .parent.parent.children(roleName: 'list item', recursive: false)
    .map { |item| item.name }
  expected_addons.each do |addon|
    result = actual_addons.find { |e| e.start_with?(addon) }
    assert_not_nil(result)
    actual_addons.delete(result)
  end
  assert_equal(0, actual_addons.size)
end

When /^I go into Enigmail's preferences$/ do
  $vm.focus_window('Icedove')
  @screen.type("a", Sikuli::KeyModifier.ALT)
  icedove_main.child('Preferences', roleName: 'menu item').click
  @enigmail_prefs = icedove_app.dialog('Enigmail Preferences')
end

When /^I enable Enigmail's expert settings$/ do
  @enigmail_prefs.button('Display Expert Settings and Menus').click
end

Then /^I click Enigmail's (.+) tab$/ do |tab_name|
  @enigmail_prefs.child(tab_name, roleName: 'page tab').click
end

Then /^I see that Enigmail is configured to use the correct keyserver$/ do
  keyservers = @enigmail_prefs.child(
    'Specify your keyserver(s):', roleName: 'entry'
  ).text
  assert_equal('hkps://hkps.pool.sks-keyservers.net', keyservers)
end

Then /^I see that Enigmail is configured to use the correct SOCKS proxy$/ do
  gnupg_parameters = @enigmail_prefs.child(
    'Additional parameters for GnuPG', roleName: 'entry'
  ).text
  assert_not_nil(
    gnupg_parameters['--keyserver-options http-proxy=socks5h://127.0.0.1:9050']
  )
end

Then /^I see that Torbirdy is configured to use Tor$/ do
  icedove_main.child(roleName: 'status bar')
    .child('TorBirdy Enabled:    Tor', roleName: 'label').wait
end

When /^I enter my email credentials into the autoconfiguration wizard$/ do
  icedove_wizard.child('Email address:', roleName: 'entry')
    .typeText($config['Icedove']['address'])
  icedove_wizard.child('Password:', roleName: 'entry')
    .typeText($config['Icedove']['password'])
  icedove_wizard.button('Continue').click
  # This button is shown if and only if a configuration has been found
  icedove_wizard.button('Done').wait(120)
end

Then /^the autoconfiguration wizard defaults to secure (incoming|outgoing) (.+)$/ do |type, protocol|
  type = type.capitalize + ':'
  assert_not_nil(
    icedove_wizard.child(type, roleName: 'entry').text
      .match(/^#{protocol},[^,]+, (SSL|STARTTLS)$/)
  )
end

When /^I fetch my email$/ do
  account = icedove_main.child($config['Icedove']['address'],
                               roleName: 'table row')
  account.click
  icedove_main = icedove_app.child("#{$config['Icedove']['address']} - Icedove Mail/News", roleName: 'frame')

  icedove_main.child('Mail Toolbar', roleName: 'tool bar')
    .button('Get Messages').click
  fetch_progress = icedove_main.child(roleName: 'status bar')
                     .child(roleName: 'progress bar')
  fetch_progress.wait_vanish(120)
end

When /^I accept the autoconfiguration wizard's (default|alternative) \((IMAP|POP3?)\) choice$/ do |type, protocol|
  protocol = 'POP3' if protocol == 'POP'
  if type == 'alternative'
    if protocol == 'IMAP'
      choice = 'IMAP (remote folders)'
    else
      choice = 'POP3 (keep mail on your computer)'
    end
    icedove_wizard.child(choice, roleName: 'radio button').click
  end
  step "the autoconfiguration wizard defaults to secure incoming #{protocol}"
  icedove_wizard.button('Done').click
  # The account isn't fully created before we fetch our mail. For
  # instance, if we'd try to send an email before this, yet another
  # wizard will stat, indicating (incorrectly) that we do not have an
  # account set up yet.
  step 'I fetch my email'
end

When /^I send an email to myself$/ do
  icedove_main.child('Mail Toolbar', roleName: 'tool bar').button('Write').click
  compose_window = icedove_app.child('Write: (no subject)')
  compose_window.wait(10)
  compose_window.child('To:', roleName: 'autocomplete').child(roleName: 'entry')
    .typeText($config['Icedove']['address'])
  # The randomness of the subject will make it easier for us to later
  # find *exactly* this email. This makes it safe to run several tests
  # in parallel.
  @subject = "Automated test suite: #{random_alnum_string(32)}"
  compose_window.child('Subject:', roleName: 'entry')
    .typeText(@subject)
  compose_window = icedove_app.child("Write: #{@subject}")
  compose_window.child('about:blank', roleName: 'document frame')
    .typeText('test')
  compose_window.child('Composition Toolbar', roleName: 'tool bar')
    .button('Send').click
  compose_window.wait_vanish(120)
end

Then /^I can find the email I sent to myself in my inbox$/ do
  folder_view = icedove_main.child($config['Icedove']['address'],
                               roleName: 'table row').parent
  inbox = folder_view.children(roleName: 'table row', recursive: false).find do |e|
    e.name.match(/^Inbox( .*)?$/)
  end
  inbox.click
  filter = icedove_main.child('Filter these messages <Ctrl+Shift+K>',
                              roleName: 'entry')
  filter.typeText(@subject)
  hit_counter = icedove_main.child('1 message')
  hit_counter.wait
  inbox_view = hit_counter.parent
  message_list = inbox_view.child(roleName: 'table')
  the_message = message_list.children(roleName: 'table row').find do |message|
    # The message will be cropped in the list, so we cannot search for
    # the full message.
    message.name.start_with?("Automated test suite:")
  end
  assert_not_nil(the_message)
  # Let's clean up
  the_message.click
  inbox_view.button('Delete').click
end
