# Token Empire: privacy

Token Empire does not track you and collects no data.

- **No tracking.** No advertising, no analytics, no advertising identifier (IDFA), no data brokers. The app never shows the App Tracking Transparency prompt because it has nothing to ask for: it doesn't link the AppTrackingTransparency framework, and the iOS export writes `NSPrivacyTracking = false` with no tracking domains into the app's privacy manifest (`privacy/tracking_enabled=false` in `export_presets.cfg`).
- **No data leaves the device.** The game, your save, your streak, the League (its rival labs are simulated on your device), your lab's name and friend code all live on the device. The game makes no network requests.
- **Purchases** of sparks go through Apple's App Store (StoreKit) or Google Play Billing. The game only learns that a purchase completed; it never sees payment details.
- **Reminders** are local notifications scheduled on the device; you choose which kinds you get.
- **Sharing** a snapshot or invite uses your device's share sheet; nothing is sent anywhere unless you choose to share it.

## App Store Connect: App Privacy answers

- "Do you or your third-party partners collect data from this app?" **No, we do not collect data from this app** (shows as "Data Not Collected").
- Tracking: **not used**. Don't declare any data as "used to track you". If tracking were declared, App Review would expect an App Tracking Transparency prompt, which this app correctly doesn't show (guideline 2.1 "Information Needed" rejection).

Google Play Data safety: no data collected, no data shared.

If an ads or analytics SDK is ever added, these answers must change and the App Tracking Transparency prompt must be shown before any tracking data is collected.
