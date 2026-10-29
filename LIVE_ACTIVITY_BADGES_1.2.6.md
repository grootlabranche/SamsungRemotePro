# SamsungRemotePro 1.2.6 — Live Activity badges

- Removed all image/logo data from Live Activity launcher buttons.
- Each pinned TV app is represented by a colored text badge and a short acronym (Apple Music = AM, YouTube = YT, Disney+ = D+, Prime Video = PV, Netflix = N, Spotify = SP, Plex = PX).
- Other apps receive a stable color derived from their identifier and an acronym derived from their name.
- The original app identifier remains attached to each button, so the launch action is unchanged.
- This substantially reduces ActivityKit state size and removes image decoding from Live Activity rendering.
- Settings label remains “Dynamic Island / Live Activity”.

## Apple Watch
This project currently has no watchOS app target. iOS does not allow an iPhone app to force-launch its companion app on an Apple Watch. A separate watchOS target would be required to provide a Watch remote; the user must open that app on the Watch themselves.

Build/device testing still requires Xcode and a compatible Apple device.
