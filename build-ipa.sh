#!/bin/bash
# Rebuilds OnThisDay from source and produces an installable .ipa for SideStore.
# Usage: ./build-ipa.sh
set -euo pipefail
cd "$(dirname "$0")"

# xcodegen regenerates the .xcodeproj from project.yml each run, which doesn't carry
# a DEVELOPMENT_TEAM (left blank there so the public template stays generic) — so your
# team ID lives in the untracked .team-id file and gets passed as a build override below.
if [ ! -f .team-id ]; then
  echo "No .team-id file found. Open OnThisDay.xcodeproj in Xcode once, set your Team under"
  echo "Signing & Capabilities for both targets, then run:"
  echo "  grep -m1 'DEVELOPMENT_TEAM = ' OnThisDay.xcodeproj/project.pbxproj"
  echo "and save the ID it prints into a .team-id file in this directory."
  exit 1
fi
TEAM_ID=$(cat .team-id | tr -d '[:space:]')

xcodegen

rm -rf build
if command -v xcbeautify >/dev/null 2>&1; then
  xcodebuild archive \
    -project OnThisDay.xcodeproj \
    -scheme OnThisDay \
    -archivePath build/OnThisDay.xcarchive \
    -destination "generic/platform=iOS" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    | xcbeautify
else
  xcodebuild archive \
    -project OnThisDay.xcodeproj \
    -scheme OnThisDay \
    -archivePath build/OnThisDay.xcarchive \
    -destination "generic/platform=iOS" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID"
fi

cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>development</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>compileBitcode</key>
	<false/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath build/OnThisDay.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist build/ExportOptions.plist

IPA="build/export/OnThisDay.ipa"
if [ -f "$IPA" ]; then
  echo ""
  echo "Built: $(pwd)/$IPA"
  echo "AirDrop this to your phone and open it with SideStore to install the update."
else
  echo "Export finished but no .ipa found — check the xcodebuild output above."
  exit 1
fi
