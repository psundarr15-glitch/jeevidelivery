# JEEVI Delivery Partner App

Flutter app for delivery partners, talking to the same CodeIgniter backend
as `customer_app` (`https://food.tvkomalur.xyz/api`), via
`Api\DeliveryApiController` / `Api\DeliveryAuthApiController`. UI matches
the JEEVI Partner reference mockups (12-screen set: Splash, Login,
Dashboard, New Order, Order Accepted, Picked Up, On the Way, Delivered,
Earnings, My Orders, Wallet, Profile).

**Backend migrations required** — run `php spark migrate` after deploying
the updated backend, or the newer endpoints (OTP, wallet, device tokens)
will fail:
- `delivery_device_tokens` (push notifications)
- `delivery_otps` (SMS OTP login/register)
- `delivery_wallet_transactions` + `delivery_partners.wallet_balance`

## What's built

**Auth**
- Password login by **phone number** (matches the mockup's "Mobile
  Number" field — the backend's `login()` now checks `phone`, not email).
- **Login with OTP** — SMS via Twilio (`app/Libraries/TwilioService.php`,
  raw curl, no SDK dependency), using the `twilio.accountSid` /
  `twilio.authToken` / `twilio.fromNumber` keys already in `.env`.
- **Register** now requires verifying your phone with an OTP inline
  (send code → confirm → rest of the form unlocks) before the backend
  will accept the signup — enforced server-side in `register()`, not
  just in the app.
- "Forgot Password?" currently routes to the OTP login flow rather than
  a separate reset-password screen — logging in via OTP covers the
  immediate need; a dedicated password-reset-via-SMS flow is a
  follow-up if partners expect the literal wording.

**Dashboard** — hamburger drawer, greeting, online/offline switch,
today's earnings card, stats (delivered today / ongoing / rating),
quick-actions grid. New broadcast orders auto-open the New Order screen
in real time (via the 20s poll and/or push notification) rather than
being listed inline, matching the reference flow.

**Order flow** — five dedicated stage screens wired to actual
`order_status` transitions, with a shared router
(`orders/order_flow_router.dart`) that fetches an order and opens
whichever screen matches its current status (used by the dashboard
popup, My Orders taps, and notification taps alike):
- New Order (30s soft-expire countdown, Accept/Reject)
- Order Accepted (items, total, "Picked Up" → `out_for_delivery`)
- Order Picked Up (transient success screen)
- On the Way (live map, call/directions, "Reached Customer" → `delivered`)
- Order Delivered (earning, cash-to-collect, Upload Proof stub)

**My Orders** — All/Ongoing/Completed/Cancelled tabs, backed by a new
`GET /delivery/orders` history endpoint (the old dashboard endpoint only
ever returned pending + active).

**Earnings** — Daily/Weekly/Monthly toggle over real `today_earnings`/
`weekly_earnings`/`monthly_earnings` figures (now based on **delivery
fee**, not full order total — see Known gaps).

**Wallet** — balance + transaction ledger, backed by a new
`delivery_wallet_transactions` table. A delivery fee is credited
automatically the moment an order is marked delivered; withdrawals debit
the balance and log a transaction (see Known gaps re: actual payout).

**Profile** — avatar/name/phone/email, and four read-only detail
screens (Personal/Vehicle/Documents/Bank) sourced from `GET /delivery/me`.

**Push notifications** — every available partner's devices get a "New
order available!" push the moment a customer checks out
(`PushNotificationService::sendToAvailablePartners`, called from
`CheckoutApiController::placeOrder`). Tapping one opens that order
directly via the same status router. Reuses the existing Firebase
service-account credentials (`firebase.projectId` /
`firebase.credentialsPath`) — just needs a `google-services.json` for
this app's package name (see the CI workflow's Firebase step).

**Live location** — pushed to the backend every 15s while an order is
out for delivery, feeding the customer app's tracking map.

## Known gaps / follow-ups

- **"Tips" and "Incentives" on the Earnings screen show ₹0.** There's no
  tipping or incentive mechanism anywhere in this codebase yet (the
  customer app has no tip-the-driver flow at all) — these are shown
  structurally to match the mockup but are honestly zero, not
  fabricated numbers. Building real tipping is a separate feature.
- **Withdrawals aren't actually paid out.** `POST /delivery/wallet/withdraw`
  debits the in-app balance and logs it, but there's no bank-transfer
  pipeline — someone operating the backend still has to pay the partner
  manually and there's no admin UI listing pending withdrawals yet.
- **Earnings model changed**: partner earnings (dashboard, wallet
  credits) are now based on `delivery_fee` per order, not the full order
  `total` as before this change. This is the economically correct
  number, but note it if you're comparing against old dashboard figures.
- **Location tracking is foreground-only** — no background isolate, so
  it pauses if the app is backgrounded mid-delivery.
- **English only** — no Tamil localization yet, unlike the customer app.
- **Placeholder app icon** — currently reuses the customer app's icon;
  swap in delivery-branded artwork before shipping.
- `dashboard()`'s pending-order broadcast doesn't filter on
  `is_available` server-side (matches the existing web dashboard's
  behavior) — going offline stops new *assignments* but won't hide
  already-broadcast orders from the pending list.
- Settings and Help & Support are placeholder screens (no real settings
  or in-app support channel exist yet).
- Personal/Vehicle/Documents/Bank Details are **read-only** — there's no
  update-profile endpoint yet, so editing still has to go through
  whoever operates the backend.

## Running it

```
flutter pub get
flutter create --platforms=android --org com.jeevi .   # generates android/ (not committed)
flutter run
```

CI (`.github/workflows/build-apk.yml`) builds a release APK, including
optional Firebase setup (see its comments for the
`DELIVERY_GOOGLE_SERVICES_JSON_BASE64` secret).
