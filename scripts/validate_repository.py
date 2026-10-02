"""Structural checks runnable on Windows. These do not compile or execute Swift."""
from pathlib import Path
import json
import plistlib
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def check(condition, description):
    if not condition:
        raise SystemExit("FAIL: " + description)
    print("OK: " + description)


def main():
    project = (ROOT / "Unforgeter.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
    source_paths = re.findall(r'lastKnownFileType = sourcecode.swift; path = "([^"]+)"', project)
    check(all((ROOT / path).is_file() for path in source_paths), "Xcode source references exist")
    expected = {p.relative_to(ROOT).as_posix() for p in (ROOT / "Unforgeter").rglob("*.swift")}
    check(set(source_paths) == expected and len(source_paths) == len(expected), "Every app Swift source appears exactly once")
    defined = re.findall(r'^\s*([A-F0-9]{24}) = \{isa = ', project, re.MULTILINE)
    referenced = set(re.findall(r'\b[A-F0-9]{24}\b', project))
    check(set(defined) == referenced and len(defined) == len(set(defined)), "Xcode object references resolve without duplicate IDs")
    scheme = ET.parse(ROOT / "Unforgeter.xcodeproj/xcshareddata/xcschemes/Unforgeter.xcscheme")
    check(all(e.attrib["BlueprintIdentifier"] in defined for e in scheme.iter("BuildableReference")), "Shared scheme targets resolve")
    with (ROOT / "Unforgeter/Resources/Info.plist").open("rb") as f:
        info = plistlib.load(f)
    check(all(info.get(k) for k in ["NSLocationWhenInUseUsageDescription", "NSLocationAlwaysAndWhenInUseUsageDescription"]), "Location permission explanations are present")
    check("location" not in info.get("UIBackgroundModes", []), "Region-only proof does not request continuous background GPS")
    backlog = json.loads((ROOT / "docs/backlog.json").read_text(encoding="utf-8-sig"))
    issues = backlog["issues"]
    check(len(issues) == 46 and len({i["localId"] for i in issues}) == 46, "All 46 unique planned backlog items are present")
    check(len(backlog["milestones"]) == 5, "All five planned milestones are present")
    for path in ["docs/product-brief.md", "docs/architecture.md", "docs/geofencing-validation.md", "Packages/UnforgeterCore/Package.swift"]:
        check((ROOT / path).is_file(), path + " exists")
    print("Structural checks passed. Swift compilation, XCTest, and physical-device delivery are separate checks.")


if __name__ == "__main__":
    main()
