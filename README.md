# On This Day

Swipe through photos taken on today's date in every past year. Right keeps, left marks for deletion, then review and delete in one go. Includes a Home Screen widget that shows today's count and a cover photo, and opens the app.

## Build

```bash
brew install xcodegen
xcodegen            # generates OnThisDay.xcodeproj from project.yml
open OnThisDay.xcodeproj
```

1. In Xcode, Settings → Accounts, add your Apple ID (free is fine).
2. Select each target (OnThisDay, OnThisDayWidget) → Signing & Capabilities → Team: your Personal Team. If the bundle ID is taken, change the `com.prandell` prefix in `project.yml` and re-run `xcodegen`.
3. On the iPhone: Settings → Privacy & Security → Developer Mode → on.
4. Plug in, pick the phone as the run destination, ⌘R.
5. First launch: allow **Full Access** to Photos.

## Free signing

A free Personal Team build stops launching after 7 days. Re-run from Xcode, or install via SideStore/AltStore to re-sign it weekly over Wi-Fi. The widget extension uses an extra App ID (free accounts get 10 per 7 days).

## How it behaves

- Pulls from iCloud when Optimise iPhone Storage is on, so the first few cards can take a second.
- Photos you keep are remembered and hidden on later visits; toggle "Show photos I kept" in the menu.
- Delete goes through iOS's own confirmation, lands in Recently Deleted for 30 days, and syncs to iCloud everywhere.
- 29 Feb only matches leap years.
