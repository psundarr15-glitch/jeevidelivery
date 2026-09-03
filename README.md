# JEEVI Delivery Partner App

Flutter app for delivery partners, talking to the same CodeIgniter backend
as `customer_app` (`https://food.tvkomalur.xyz/api`), via the existing
`Api\DeliveryApiController` / `Api\DeliveryAuthApiController` endpoints.
Three endpoints (`GET /delivery/me`, `POST /delivery/toggle-availability`,
`POST /delivery/device-token`) were added to the backend to support this
app, plus a new `delivery_device_tokens` table — **run migrations**
(`php spark migrate`) after deploying the updated backend, or the
device-token endpoint will fail.

## What's built (v1)

- **Login / Register** — register posts multipart (photo, ID proof, RC
  document uploads) to the same validation rules as the web signup flow.
- **Home / Dashboard** — online/offline toggle, today/week/month earnings,
  active deliveries, and incoming order requests with Accept/Reject.
  Polls the dashboard every 20s so new broadcast orders show up without
  a manual pull-to-refresh.
- **Order details** — pickup/drop-off info with one-tap call and
  directions, item list, payment method/status, a small map of the
  drop-off point, and a single "advance status" button that walks the
  order through confirmed → preparing → out for delivery → delivered.
- **Live location** — while an order is out for delivery, the device's
  location is pushed to the backend every 15s (`LocationTracker`), which
  is what feeds the customer app's live order-tracking map.
- **Push notifications** — every available partner's devices get a
  "New order available!" push the moment a customer places an order
  (`PushNotificationService::sendToAvailablePartners`, called from
  `CheckoutApiController::placeOrder`), backed by a new
  `delivery_device_tokens` table + `POST /delivery/device-token`.
  Tapping the notification opens that order directly. Reuses the same
  Firebase service-account credentials the chat feature already needs
  (`firebase.projectId` / `firebase.credentialsPath` in `.env`) — no new
  backend config required, just a `google-services.json` for this app
  (see the CI workflow's Firebase step for setup). The 20s dashboard
  poll stays on as a backstop for whenever push doesn't arrive.
- **Earnings tab**, **Profile tab** (partner info + logout).

## Known gaps / follow-ups

- **Location tracking is foreground-only.** No background isolate/
  platform channel is set up, so tracking pauses if the app is
  backgrounded. Fine for v1; a background service is a real follow-up
  before this ships to partners who alt-tab to other apps mid-delivery.
- **English only** — no Tamil localization yet, unlike the customer app.
- No app icon of its own yet — currently reuses the customer app's icon
  as a placeholder (`assets/icon/`); swap in delivery-branded artwork
  before shipping.
- `dashboard()`'s pending-order broadcast doesn't filter on
  `is_available` server-side (matches the existing web dashboard's
  behavior) — going offline stops new *assignments* but won't hide
  already-broadcast orders from the pending list. Worth revisiting if
  partners expect "offline" to mean fully hidden.

## Running it

```
flutter pub get
flutter create --platforms=android --org com.jeevi .   # generates android/ (not committed)
flutter run
```

CI (`.github/workflows/build-apk.yml`) builds a release APK the same way
`customer_app`'s workflow does, minus the Firebase/push-notification
steps this app doesn't need.
