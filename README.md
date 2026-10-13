# RollCull

**The entire app is a spinning sausage.**

Open RollCull and behold a sausage, rotating forever. Tap the sausage to pause or resume.

## Features

- A full-screen sausage drawn with SwiftUI, with no image downloads.
- Continuous rotation while the app is active; animation pauses when it leaves the foreground.
- Tap to pause or resume, with an accessible control for VoiceOver.
- Reduce Motion keeps the sausage still.
- Small and medium Home Screen widgets show the same sausage. Tap either widget to open the app.
- No Photos permission, photo-library reads, accounts, servers, or analytics in the sausage experience.

The widget is a still image: [WidgetKit limits animations to two seconds](https://developer.apple.com/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities). The app is where the sausage spins.

The previous photo-review screens remain in the source tree but are no longer reachable from the app or its widget links.

## Requirements

iOS 17 or later. Building requires a Mac with the full Xcode application installed.

## Building from source

```bash
brew install xcodegen
xcodegen                 # generates OnThisDay.xcodeproj from project.yml
open OnThisDay.xcodeproj
```

Run the `OnThisDay` scheme in an iPhone simulator. To run on a phone, select your team under Signing & Capabilities for both targets, enable Developer Mode on your phone, and run.

An unsigned simulator build can also be made from the command line:

```bash
xcodegen
xcodebuild -project OnThisDay.xcodeproj -scheme OnThisDay \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

To make an installable `.ipa` for SideStore or AltStore, save your Team ID to a `.team-id` file in the repo root and run:

```bash
./build-ipa.sh
```

If either bundle ID is taken, change the app and widget `PRODUCT_BUNDLE_IDENTIFIER` values in `project.yml` before generating the project.

## Manual checks

- Launch the app and confirm the sausage spins without a Photos permission prompt.
- Tap to pause, tap again to resume, and repeat with VoiceOver enabled.
- Background and reopen the app; confirm rotation resumes unless it was manually paused.
- Enable Reduce Motion in Settings > Accessibility > Motion; confirm the sausage stays still.
- Add small and medium widgets; confirm their sausages fit and tapping either opens the sausage screen.
- Open `onthisday://today`; confirm it also opens the sausage screen.
