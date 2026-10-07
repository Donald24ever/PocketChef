# Privacy & Data Safety declarations

This file maps what PocketChef collects to the App Store **Privacy Nutrition Label**
and the Google Play **Data safety** form. Declarations are derived from
`store/privacy-policy.md` and the in-app policy (`lib/features/legal/legal_screen.dart`).

Collected information is used solely to provide app functionality, improve performance,
personalize recommendations, secure user accounts, and maintain service quality. Data is
encrypted in transit and access is restricted to authorized systems only.

## App Store Connect — Privacy Nutrition Label

Data linked to the user (all of the following are **linked to identity**):

| Data type (App Store) | Collected | Used for | Tracking |
|---|---|---|---|
| Contact Info → Name | Yes | App Functionality | No |
| Contact Info → Email Address | Yes | App Functionality, Account Security | No |
| Identifiers → User ID | Yes (account) | App Functionality, Account Security | No |
| User Content → Photos or Videos | Yes (uploaded food images) | App Functionality | No |
| User Content → Other User Content | Yes (favourite recipes) | App Functionality, Personalization | No |
| Usage Data → Product Interaction | Yes (favourites, anonymous analytics) | Analytics, Personalization | No |
| Diagnostics → Crash Data | Yes | App Functionality | No |
| Sensitive Info | No | — | — |
| Location | No | — | — |
| Contacts | No | — | — |
| Browsing History | No | — | — |
| Purchases | No (unless subscriptions added) | — | — |

- **Tracking:** No. The app does not track users across other companies' apps or websites.
- **Data used to track you:** None.

## Google Play — Data safety

**Does your app collect or share any of the required user data types?** Yes — collected,
not shared with third parties except as required to run the service.

| Data type (Play) | Collected | Shared | Purpose | Optional |
|---|---|---|---|---|
| Personal info → Name | Yes | No | App functionality | No |
| Personal info → Email address | Yes | No | App functionality, Account management | No |
| Personal info → User IDs | Yes | No | Account management / security | No |
| Photos and videos → Photos | Yes | No | App functionality (ingredient detection) | No |
| App activity → Other actions (favourites) | Yes | No | App functionality, Personalization | No |
| App info and performance → Crash logs | Yes | No | App functionality / stability | No |
| App info and performance → Diagnostics (anonymous analytics) | Yes | No | Analytics | No |

- **Data encrypted in transit:** Yes.
- **Users can request data deletion:** Yes.
  - In-app: **Profile → Privacy & security → Delete my account** (immediate where
    technically possible, and no later than 30 days after submission).
  - Web: `https://pocketchef.app/delete-account`.

## Deletion behaviour (as implemented / to implement)

On account deletion the following are removed:

1. Profile information
- Saved recipes
- Uploaded content
- Authentication records

Processed immediately where technically possible and no later than 30 days after
submission.

> Backend note: with a real Firebase backend this maps to deleting the Firestore user
> document and subcollections, deleting Storage objects for uploaded images, and deleting
> the Firebase Authentication user record. See `firestore.rules` for the owner-scoped,
  deny-by-default rules that support owner-initiated deletion.