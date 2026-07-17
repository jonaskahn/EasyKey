#!/usr/bin/env python3
"""Insert a new Sparkle appcast <item> for a released DMG, keeping prior items.

Usage: generate-appcast.py <appcast-path> <version> <build> <dmg-url> \
    <dmg-length> <ed-signature> <min-system-version> <pub-date>

If <appcast-path> does not exist, a new appcast document is created.
"""
import sys
import xml.etree.ElementTree as ET

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


def sparkle_tag(name):
    return f"{{{SPARKLE_NS}}}{name}"


def load_or_create_channel(appcast_path):
    try:
        with open(appcast_path, "rb") as f:
            contents = f.read()
        if b"<!DOCTYPE" in contents:
            raise ValueError("Refusing to parse appcast containing a DOCTYPE declaration.")
        tree = ET.ElementTree(ET.fromstring(contents))
        channel = tree.getroot().find("channel")
        return tree, channel
    except FileNotFoundError:
        rss = ET.Element("rss", {"version": "2.0"})
        channel = ET.SubElement(rss, "channel")
        ET.SubElement(channel, "title").text = "EasyKey Updates"
        return ET.ElementTree(rss), channel


def build_item(version, build, dmg_url, dmg_length, signature, min_system_version, pub_date):
    item = ET.Element("item")
    ET.SubElement(item, "title").text = f"Version {version}"
    ET.SubElement(item, "pubDate").text = pub_date
    ET.SubElement(item, sparkle_tag("version")).text = build
    ET.SubElement(item, sparkle_tag("shortVersionString")).text = version
    ET.SubElement(item, sparkle_tag("minimumSystemVersion")).text = min_system_version
    ET.SubElement(item, "enclosure", {
        "url": dmg_url,
        "length": dmg_length,
        "type": "application/octet-stream",
        sparkle_tag("edSignature"): signature,
    })
    return item


def main():
    (appcast_path, version, build, dmg_url, dmg_length,
     signature, min_system_version, pub_date) = sys.argv[1:9]

    tree, channel = load_or_create_channel(appcast_path)
    new_item = build_item(version, build, dmg_url, dmg_length, signature, min_system_version, pub_date)

    existing_items = channel.findall("item")
    insert_index = list(channel).index(existing_items[0]) if existing_items else len(list(channel))
    channel.insert(insert_index, new_item)

    ET.indent(tree, space="    ")
    tree.write(appcast_path, encoding="UTF-8", xml_declaration=True)


if __name__ == "__main__":
    main()
