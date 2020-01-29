import logging
import pipes

import tailsgreeter.config
from tailsgreeter.settings.utils import read_settings, write_settings

NETCONF_DIRECT = "direct"
NETCONF_OBSTACLE = "obstacle"
NETCONF_DISABLED = "disabled"


class NetworkSetting(object):
    """Setting controlling how Tails connects to Tor"""

    def __init__(self):
        self.settings_file = tailsgreeter.config.network_setting_path

    def save(self, value: str):
        write_settings(self.settings_file, {
            'TAILS_NETCONF': pipes.quote(value),
        })
        logging.debug('network setting written to %s', self.settings_file)

    def load(self) -> {bool, None}:
        try:
            settings = read_settings(self.settings_file)
        except FileNotFoundError:
            logging.debug("No persistent network settings file found (path: %s)", self.settings_file)
            return None

        value = settings.get('TAILS_NETCONF')
        if value is None:
            logging.debug("No network setting found in settings file (path: %s)", self.settings_file)
            return None

        logging.debug("Loaded network setting '%s'", value)
        return value
