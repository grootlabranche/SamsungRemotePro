#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

command -v swiftc >/dev/null || { echo "swiftc is required" >&2; exit 2; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 2; }

# Parse every Swift source and test file without requiring a connected device.
while IFS= read -r -d '' file; do
  swiftc -frontend -parse "$file" >/dev/null
done < <(find . -name '*.swift' -not -path './.git/*' -print0)

python3 - <<'PYCODE'
import pathlib
import plistlib
import re

root = pathlib.Path(".")
plist_names = (
    "Config/Info.plist",
    "Config/WidgetInfo.plist",
    "WatchApp/Info.plist",
)
loaded = {}
for name in plist_names:
    with (root / name).open("rb") as stream:
        loaded[name] = plistlib.load(stream)

# Keep bundle/version metadata generated consistently from the target settings.
for name, info in loaded.items():
    assert info.get("CFBundleIdentifier") == "$(PRODUCT_BUNDLE_IDENTIFIER)", (
        f"{name}: CFBundleIdentifier must come from PRODUCT_BUNDLE_IDENTIFIER"
    )
    assert info.get("CFBundleShortVersionString") == "$(MARKETING_VERSION)", (
        f"{name}: version must come from MARKETING_VERSION"
    )
    assert info.get("CFBundleVersion") == "$(CURRENT_PROJECT_VERSION)", (
        f"{name}: build number must come from CURRENT_PROJECT_VERSION"
    )

watch = loaded["WatchApp/Info.plist"]
assert watch.get("CFBundleExecutable") == "$(EXECUTABLE_NAME)"
assert watch.get("CFBundlePackageType") == "APPL"
assert watch.get("WKCompanionAppBundleIdentifier") == "fr.samsungremotepro.app"

project = (root / "SamsungRemotePro.xcodeproj/project.pbxproj").read_text()
for bundle_id in (
    "fr.samsungremotepro.app",
    "fr.samsungremotepro.app.widgets",
    "fr.samsungremotepro.app.watchkitapp",
):
    assert f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};" in project, (
        f"Missing target bundle identifier: {bundle_id}"
    )
assert re.search(r"MARKETING_VERSION\s*=\s*[^;]+;", project), "Missing marketing version"
assert re.search(r"CURRENT_PROJECT_VERSION\s*=\s*[^;]+;", project), "Missing build number"
assert 'PHE2 = {isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = (B045, ); name = "Embed Watch Content";' in project, "Xcode 26 requires the single-target Watch app to be embedded in PlugIns"

# Keep existing launcher safeguards covered by the static validation.
assert "3500" in (root / "Sources/Services/LiveActivityManager.swift").read_text()
assert 'return "AM"' in (root / "Widgets/RemoteLiveActivity.swift").read_text()
assert "customIconData: nil" in (root / "Sources/Views/RemoteControlView.swift").read_text()
assert "Dynamic Island / Live Activity" in (root / "Sources/Views/SecondaryViews.swift").read_text()
print("Static validation passed: Swift syntax, app/widget/watch plist metadata, and launcher invariants.")
PYCODE
echo "Static validation complete. This does not replace the full Xcode archive or device tests."
