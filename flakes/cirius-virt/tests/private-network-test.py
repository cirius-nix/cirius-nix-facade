import importlib.util
from pathlib import Path
import tempfile
import sys
import unittest
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True

source = Path(__file__).resolve().parents[1] / "modules/nixos/family-media/private-network.py"
spec = importlib.util.spec_from_file_location("private_network", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PrivateNetworkTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "network.xml"

    def test_first_start_and_repeat(self):
        module.configure(self.path)
        first = self.path.read_bytes()
        module.configure(self.path)
        self.assertEqual(first, self.path.read_bytes())
        root = ET.parse(self.path).getroot()
        self.assertEqual(root.findtext("LocalNetworkAddresses/string"), "127.0.0.1")
        self.assertEqual(root.findtext("EnableIPv6"), "false")
        self.assertEqual(root.findtext("AutoDiscovery"), "false")
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)

    def test_preserve_unrelated_settings_and_mode(self):
        self.path.write_text('''<NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <!-- user setting -->
        <BaseUrl>/jellyfin</BaseUrl><InternalHttpPort>8097</InternalHttpPort>
        <LocalNetworkAddresses><string>0.0.0.0</string></LocalNetworkAddresses>
        <EnableIPv6>true</EnableIPv6><AutoDiscovery>true</AutoDiscovery>
        </NetworkConfiguration>''')
        self.path.chmod(0o640)
        module.configure(self.path)
        root = ET.parse(self.path).getroot()
        self.assertEqual(root.findtext("BaseUrl"), "/jellyfin")
        self.assertEqual(root.findtext("InternalHttpPort"), "8097")
        self.assertEqual(root.findtext("EnableIPv6"), "false")
        self.assertIn("user setting", self.path.read_text())
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o640)

    def test_invalid_configs_fail_without_replacing(self):
        for text in (
            "<broken",
            "<OtherRoot/>",
            "<NetworkConfiguration><EnableIPv4/><EnableIPv4/></NetworkConfiguration>",
            "<NetworkConfiguration><LocalNetworkAddresses/><LocalNetworkAddresses/></NetworkConfiguration>",
        ):
            with self.subTest(text=text):
                self.path.write_text(text)
                with self.assertRaises((ET.ParseError, ValueError)):
                    module.configure(self.path)
                self.assertEqual(self.path.read_text(), text)

    def test_symlink_fails_without_replacing(self):
        other = self.path.with_name("other.xml")
        other.write_text("<NetworkConfiguration/>")
        self.path.symlink_to(other)
        with self.assertRaises(ValueError):
            module.configure(self.path)
        self.assertTrue(self.path.is_symlink())
        self.assertEqual(other.read_text(), "<NetworkConfiguration/>")


if __name__ == "__main__":
    unittest.main()
