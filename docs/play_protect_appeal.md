# Google Play Protect Appeal — Hoda (v0.1.4, versionCode 14)

Fill-in guide for: https://support.google.com/googleplay/android-developer/contact/protectappeals
(Removed / flagged by Play Protect — appeal form)

---

## Section: «Additional information to support your appeal» *

Copy-paste the text below (English, concise, factual):

---

Hi,

Thank you for reviewing our appeal.

**About the app**
Hoda (package: com.hoda.hoda) is a free, open-source, fully offline Persian-language spiritual companion app. It displays curated religious content — Quranic verses with Persian translations, short narrations of the Fourteen Infallibles, wills of fallen soldiers (a well-documented cultural genre in Iran), and Nahj al-Balagha wisdom sayings — together with a simple tap counter for daily devotional phrases. The entire content database ships inside the APK; the app fetches nothing from the internet.

**What the app actually does**
- Reads a bundled, read-only SQLite database (verses, hadiths, wisdom sayings, wills, daily remembrances).
- Shows one card of content per day on the home screen and offers full browsing lists.
- Lets users count recitations with a tap counter (stored locally via SharedPreferences).
- Sends up to 5 user-scheduled daily notifications with today's content.

**Permissions and why we need them (complete list)**
- POST_NOTIFICATIONS — required on Android 13+ to show the user's own scheduled daily reminders. Requested at runtime; the app works without it.
- SCHEDULE_EXACT_ALARM — lets the user's chosen daily reminder time fire accurately. The app checks this at runtime and gracefully falls back to inexact scheduling when not granted.
- RECEIVE_BOOT_COMPLETED — re-arms the user's own reminders after a device reboot, so they don't silently disappear.
- VIBRATE — a short, gentle haptic pulse when the user taps the recitation counter.
- NO INTERNET permission, no location, no storage, no contacts, no ads SDKs, no analytics, no third-party trackers. No data is collected, stored remotely, or shared. There is no login.

**Why we believe the flag is a false positive**
The app has no functionality that could be considered harmful, deceptive, or unwanted: it contains no code that could install anything, no phishing surfaces, no hidden behavior, and no network activity at all. It is plain content-display plus a local counter and local notifications. All source code is publicly available for review at https://github.com/dnh-bit/hoda, and every release is reproducible from that repository through public GitHub Actions workflows.

We are fully committed to Google Play policies. If any specific behavior triggered this flag, we will gladly fix it immediately — please let us know what it was.

In conclusion, we kindly ask you to reconsider the flag and restore the app's distribution. We appreciate your support and hope to contribute positively to the user community.

Thank you for your attention.
Best regards,
The Hoda development team
Contact: (your email)
Source: https://github.com/dnh-bit/hoda
Latest release: https://github.com/dnh-bit/hoda/releases/latest

---

## Other fields on the form (quick guide)

- **Developer name:** the name on your Play Console account.
- **App name:** Hoda
- **Package name:** com.hoda.hoda
- **Version:** 0.1.4 (versionCode 14)
- **Where the app is distributed:** APK signed with a stable keystore; also published on GitHub Releases (public, reproducible builds).
- **Appeal type / reason:** «App was incorrectly flagged/removed by Google Play Protect» — choose the closest option; if asked whether the app is published by you, answer Yes.
- **Contact email:** an email on your developer account domain.

## Tips

1. Keep the appeal in English and factual; don't mention other stores as "competitors".
2. Attach nothing sensitive; the GitHub link is your strongest evidence.
3. If the form asks for SHA-256 of the APK signing certificate, get it with:
   `keytool -printcert -jarfile hoda-v0.1.4.apk | grep SHA256`
4. After submission, replies usually arrive by email within 1–7 days. If rejected again, reply asking for the specific policy or detection verdict name (e.g. "Trojan:Generic / PUA:…") so you can address it precisely.

## ⚡ Short version (≤1000 chars — for the form's character limit)

The form limits «Additional information» to 1000 characters. This version is 996 chars — copy it directly:

```
Hi,

Hoda (package: com.hoda.hoda) is a free, open-source, fully OFFLINE Persian spiritual app: Quranic verses with Persian translations, narrations of the Fourteen Infallibles, wills of fallen soldiers (a well-documented cultural genre in Iran) and Nahj al-Balagha sayings, plus a local tap counter. The content database ships inside the APK: the app has NO internet permission and fetches nothing.

Permissions (all): POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, VIBRATE — for the user's own daily reminders and counter haptics. No ads, no analytics, no trackers, no login, no data collection.

Nothing can install software, phish or act covertly: there is no network activity at all. All source code is public at https://github.com/dnh-bit/hoda, and releases are reproducible via public GitHub Actions.

We follow Google Play policies and will fix anything specific immediately. Please reconsider the flag and restore distribution.

Best regards,
The Hoda development team
```
