#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
command -v swiftc >/dev/null || { echo "swiftc is required" >&2; exit 2; }
while IFS= read -r -d '' file; do swiftc -frontend -parse "$file" >/dev/null; done < <(find . -name '*.swift' -print0)
python3 - <<'PYCODE'
import pathlib, plistlib
root = pathlib.Path('.')
for name in ('Config/Info.plist', 'Config/WidgetInfo.plist'):
    with (root / name).open('rb') as stream:
        plistlib.load(stream)
project = (root / 'SamsungRemotePro.xcodeproj/project.pbxproj').read_text()
assert 'MARKETING_VERSION = 1.2.6;' in project
assert 'CURRENT_PROJECT_VERSION = 8;' in project
assert '3500' in (root / 'Sources/Services/LiveActivityManager.swift').read_text()
assert 'return \"AM\"' in (root / 'Widgets/RemoteLiveActivity.swift').read_text()
assert 'customIconData: nil' in (root / 'Sources/Views/RemoteControlView.swift').read_text()
assert 'Dynamic Island / Live Activity' in (root / 'Sources/Views/SecondaryViews.swift').read_text()
print('Static validation passed.')
PYCODE
echo "Swift syntax and plist checks passed. This is not a substitute for an Xcode build or on-device ActivityKit test."
