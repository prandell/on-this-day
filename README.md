# RollCull

**Clear out your camera roll one swipe at a time.**

RollCull turns cleaning up thousands of photos into something you'll actually do. Every day it gathers what you shot on this date in past years. You swipe right to keep and left to cull, then delete the lot in one go.

## Features

**Swipe to decide**
- Right keeps, left marks for deletion. The card tints as you drag and shows a KEEP or DELETE stamp so you know which way it's going.
- Undo whenever you change your mind. Nothing is deleted until you confirm.
- Favourite, bookmark or share a photo straight from the card.
- Videos autoplay and loop, with a 1x / 1.5x / 2x speed toggle.

**Ways to work through your library**
- **On This Day:** photos and videos from today's date in every earlier year.
- **Recents:** your latest shots.
- **Random:** a fresh mixed batch each day.
- **By month:** every month you've got photos in, sorted newest or oldest first.
- **Bookmarked:** the ones you set aside to decide on later.

Each session picks up where you left off.

**Review, then delete**
- See everything you've marked in a grid first, and tap any photo to save it.
- Deletion goes through iOS's own confirmation. Photos sit in Recently Deleted for 30 days.
- After each session you get a summary of how much space you freed, plus your all-time total.

**Home Screen widget**
- Small and medium sizes show today's count over a photo from the day. Tap it to jump straight in.

**Private by design**
- Everything happens on your phone. No accounts, no servers, no analytics.
- Photos you've already kept stay out of later sessions, unless you turn them back on in Settings.

## Good to know

- Deleting a photo removes it from iCloud Photos and from every synced device too.
- If Optimise iPhone Storage is on, full-size images come down from iCloud, so the first card can take a moment.
- 29 February only shows up in leap years.

## Requirements

iOS 17 or later, with Full Access to Photos.

---

## Building from source

```bash
brew install xcodegen
xcodegen                 # generates OnThisDay.xcodeproj from project.yml
open OnThisDay.xcodeproj
```

Select your team under Signing & Capabilities for both targets, turn on Developer Mode on your phone, and run.

To make an installable `.ipa` (for SideStore or AltStore), save your Team ID to a `.team-id` file in the repo root and run:

```bash
./build-ipa.sh
```

A free Apple ID works. Builds signed with a free Personal Team expire after 7 days, so you'll need to re-run from Xcode, or let SideStore or AltStore refresh it for you. If the bundle ID is taken, change the `bundleIdPrefix` in `project.yml`.
