"""Keep only Jellyfin's network binding private, preserving other settings."""

import os
from pathlib import Path
import stat
import sys
import tempfile
import xml.etree.ElementTree as ET


def configure(path: Path) -> None:
    if path.is_symlink():
        raise ValueError("Refusing to replace a symlinked Jellyfin network config")
    exists = path.exists()
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
    root = ET.parse(path, parser=parser).getroot() if exists else ET.Element("NetworkConfiguration")
    if root.tag != "NetworkConfiguration":
        raise ValueError("Unexpected Jellyfin network config root")

    def element(name: str) -> ET.Element:
        matches = root.findall(name)
        if len(matches) > 1:
            raise ValueError(f"Duplicate Jellyfin network setting: {name}")
        return matches[0] if matches else ET.SubElement(root, name)

    addresses = element("LocalNetworkAddresses")
    addresses.clear()
    ET.SubElement(addresses, "string").text = "127.0.0.1"
    for key, value in {
        "EnableIPv4": "true",
        "EnableIPv6": "false",
        "AutoDiscovery": "false",
    }.items():
        element(key).text = value

    mode = stat.S_IMODE(path.stat().st_mode) if exists else 0o600
    fd, temporary = tempfile.mkstemp(prefix=".network-", suffix=".xml", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            os.fchmod(output.fileno(), mode)
            ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    configure(Path(sys.argv[1]))
