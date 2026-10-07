# PocketChef

Scan your kitchen — cook what you already have.

Flutter (3.47.x) + Riverpod 3 + go_router 18. All data is local demo data; no network
required to run.

## Features

- **Smart scan → pantry**: photograph ingredients, review detections, and get recipes
  built around what you have.
- **Nigerian Kitchen**: 27 hand-authored Nigerian dishes with full heritage teaching —
  state/region of origin, cultural significance, traditional occasions, historical
  background, recommended sides and drinks. Curated. Home sections, a dedicated
  `/nigerian` screen with regional index + AI food matching (tap yam/plantain/beans/
  palm oil/egusi/pepper/tomatoes/onion/fish/chicken), and a "story behind your meal"
  card on every Nigerian recipe.
- **Meal planning**: drop meals onto days, auto-plan the week, reshuffle, shop from one
  list.
- **Privacy & security** (production-seams + working demo):
  - Strong-password policy (length, case, digits, common-password and email-reuse
    checks) enforced at sign-in.
  - Brute-force lockout: 5 failed attempts locks the account for 15 minutes.
  - Email-verification flow with one-time codes (demo codes shown in the UI).
  - Session management with token refresh; security audit log of every sensitive action.
  - Biometric unlock (Face ID / Touch ID) and two-factor toggles — wired as seams for
    `local_auth` + Firebase Auth in a real deployment.
  - GDPR / UK DPA data controls: export your data and delete your account.

## Food photography

Every recipe carries a real, licensed photograph of the finished dish (no AI-generated
or illustrated food). URLs are stored on the `Recipe` model (`imageUrl`) and rendered by
`RecipeImage` (`lib/core/widgets/recipe_image.dart`), which shows a shimmer while loading,
fades the photo in, and falls back to a neutral "Image currently unavailable" placeholder
if a photo cannot be reached. On the recipe page the instructions stay hidden until the
hero photo has loaded.

- General dishes: TheMealDB (real meal photography, recipe API).
- Nigerian dishes: Wikimedia Commons (authentic Jollof, Egusi, Efo Riro, Afang, Banga,
  Ogbono, Akara, Moi Moi, Ofada, Yam Porridge, Pounded Yam, Amala, Eba, Suya, and the
  swallows/soups), retrieved and verified via the Commons API.
- All 39 URLs were verified to return HTTP 200 with an image content type.

Most Wikimedia Commons files are CC BY-SA and require attribution. The in-app
**Photo credits** screen (`/legal/credits`, linked from Profile and the welcome screen)
lists the per-file author, licence and source URL for all 39 photos
(`lib/data/seed/photo_credits.dart`, generated from the Commons API). Three images come
from TheMealDB and are credited to TheMealDB. Photos are disk-cached via
`cached_network_image`.

## Security posture

- Enforced: password policy, account lockout, email verification, session refresh,
  audit logging, encryption posture for data in transit/at rest (TLS 1.2+, device
  keychain in production).
- `firestore.rules` (repo root) documents the production backend rules: owner-scoped
  reads/writes, validated payloads, append-only audit logs, and a deny-by-default
  catch-all. Deploy with `firebase deploy --only firestore:rules`.
- Cloud sync currently reports "Demo data". To go live: create a Firebase project,
  enable Authentication (email, Google, Apple), set up Cloud Firestore, and swap the
  `DemoAuthRepository`/`DemoAiService` implementations for real ones. Biometric unlock
  additionally requires the `local_auth` plugin.

## Verify

```sh
flutter analyze
flutter test
```