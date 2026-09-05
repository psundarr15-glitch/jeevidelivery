# JEEVI Delivery Partner App

`customer_app`-க்கு எந்த CodeIgniter backend-ஆ இருக்கோ, அதே backend-கிட்டதான்
இந்த Flutter delivery partner app-உம் பேசுது (`https://food.tvkomalur.xyz/api`),
`Api\DeliveryApiController` / `Api\DeliveryAuthApiController` வழியா. UI
ரெஃபரன்ஸ் மாக்அப் (Splash, Login, Dashboard, New Order, Order Accepted,
Picked Up, On the Way, Delivered, Earnings, My Orders, Wallet, Profile —
12 screens) மாதிரியே இருக்கும்.

**Backend migration ரன் பண்ணணும்** — updated backend deploy பண்ணின உடனே
`php spark migrate` ரன் பண்ணுங்க, இல்லனா புது endpoints (OTP, wallet,
device token, cash) எல்லாம் fail ஆகும்:
- `delivery_device_tokens` (push notifications)
- `delivery_otps` (SMS OTP login/register)
- `delivery_wallet_transactions` + `delivery_partners.wallet_balance`
- `delivery_cash_transactions` + `delivery_partners.cash_in_hand`

## என்ன எல்லாம் இருக்கு

**Session handling** — Token expire ஆகி 401 வந்தா, app தானாகவே logout
ஆகி login screen-க்கு போயிடும் ("Your session expired" என்ற banner-உடன்),
"Invalid or expired token" என்ற raw error text screen-ல காட்டாது.
இது `ApiClient._decode`/`_handleUnauthorized`-ல் centralized-ஆ handle
ஆகுது. ஒவ்வொரு screen-லயும் error வந்தா `AppErrorView` fallback-ஆ
காட்டும் (auto-redirect ஏதோ காரணத்துக்கு வேலை செய்யலைன்னா, "Please Login
Again" பட்டன்-உடன்). Login screen-ல தப்பு password/phone கொடுத்தா அது
normal error-ஆவே காட்டும் (அதுக்கு token கிடையாது, அதனால அது session
expiry-ன்னு நினைச்சு logout ஆகாது).

**Registration** இப்போ 2-step wizard (progress bar, dashed-border
photo/document upload boxes, rounded fields, pill-shaped buttons) —
ரெஃபரன்ஸ் மாதிரியே, ஆனா app-ஓட ஏற்கனவே இருக்கிற சிவப்பு தீம்-ல.
Step 1-ல identity + inline phone-OTP verification + password (live
strength checklist); step 2-ல address, vehicle, documents, bank
details, terms.

**Auth**
- **Phone number**-ஆ login (மாக்அப்-ல "Mobile Number" field மாதிரி —
  backend-ஓட `login()` இப்போ email இல்ல, `phone`-ஐ தான் check பண்ணும்).
- **Login with OTP** — Twilio வழியா SMS (`app/Libraries/TwilioService.php`,
  raw curl, SDK dependency இல்ல), `.env`-ல ஏற்கனவே இருக்கிற
  `twilio.accountSid` / `twilio.authToken` / `twilio.fromNumber`
  keys-ஐ use பண்ணி.
- **Register** பண்ணும்போது phone number-ஐ OTP-ஆல verify பண்ணத்தான்
  வேண்டும் (send code → confirm → மீதி form unlock ஆகும்) — இது
  backend-லயும் (`register()`) enforce பண்ணப்பட்டிருக்கு, app-ல மட்டும்
  இல்ல.
- "Forgot Password?" இப்போ OTP login flow-க்கு தான் போகும் (தனி
  reset-password screen இன்னும் இல்ல) — OTP-ல login பண்ணுனாலே உடனடி
  தேவை தீரும்; partner-க்கு "password reset" அப்படின்னே வேணும்-ன்னா,
  அது தனி follow-up feature.

**Dashboard** — hamburger drawer, greeting, online/offline switch,
today's earnings card, stats (delivered today / ongoing / rating),
quick-actions grid. புது order வந்தா, 20-second poll மூலமா அல்லது push
notification மூலமா, New Order screen தானாகவே open ஆகும் (dashboard-ல
list-ஆ காட்டாம, ரெஃபரன்ஸ் flow மாதிரியே).

**Order flow** — order_status-ஐ பொறுத்து 5 screens, ஒரு shared router
(`orders/order_flow_router.dart`) மூலமா correct screen open ஆகும்
(dashboard popup, My Orders tap, notification tap — எல்லாத்துக்கும்
இதே router தான்):
- New Order (30-second soft-expire countdown, Accept/Reject)
- Order Accepted (items, total, "Picked Up" → `out_for_delivery`)
- Order Picked Up (transient success screen)
- On the Way (live map, call/directions, "Reached Customer" → `delivered`)
- Order Delivered (earning, cash collected, Upload Proof stub)

**My Orders** — All/Ongoing/Completed/Cancelled tabs, புது
`GET /delivery/orders` history endpoint மூலமா (பழைய dashboard endpoint
pending + active மட்டும் தான் தந்துச்சு).

**Earnings** — Daily/Weekly/Monthly toggle, real
`today_earnings`/`weekly_earnings`/`monthly_earnings` figures-உடன் (இப்போ
**delivery fee** அடிப்படையில், முழு order total இல்ல — கீழே "Known gaps"
பாருங்க).

**Wallet** — balance + transaction ledger, புது
`delivery_wallet_transactions` table மூலமா. Order delivered ஆன உடனே
delivery fee தானாகவே credit ஆகும்; withdraw பண்ணும்போது balance-ல
இருந்து debit ஆகி transaction log ஆகும் (actual bank payout பத்தி கீழே
பாருங்க).

**Profile** — avatar/name/phone/email, + 4 read-only detail screens
(Personal/Vehicle/Documents/Bank), `GET /delivery/me` மூலமா.

**Push notifications** — customer ஒரு order போட்ட உடனே, online-ஆ இருக்கிற
எல்லா partners-ஓட devices-க்கும் "New order available!" push போகும்
(`PushNotificationService::sendToAvailablePartners`,
`CheckoutApiController::placeOrder`-ல இருந்து call ஆகுது). Notification-ஐ
tap பண்ணா அதே status router மூலமா order-ஐ open பண்ணும். Chat feature
ஏற்கனவே use பண்றது Firebase credentials-ஐயே (`firebase.projectId` /
`firebase.credentialsPath`) இதுக்கும் use பண்ணுது — இந்த app-ஓட package
name-க்கு matching ஒரு `google-services.json` மட்டும் வேணும் (CI
workflow-ல Firebase step பாருங்க).

**Live location** — order out-for-delivery-ல இருக்கும்போது ஒவ்வொரு 15
seconds-க்கும் partner-ஓட location backend-க்கு போகும், customer app-ஓட
tracking map-க்கு அதுதான் feed ஆகும்.

## COD Cash Handling (Cash on Delivery)

COD cash-ஐ partner-ஓட own earning-ஆ கணக்கு போடக்கூடாது-ன்னு, wallet
earnings-ல இருந்து தனியா ஒரு "liability"-ஆ track பண்றோம்:

- COD order-ஐ "delivered"-ன்னு mark பண்ணும்போது, app-ல ஒரு explicit
  confirmation வரும் ("Yes, I've collected it") — அப்புறம் தான் status
  update ஆகும் (On the Way screen பாருங்க).
- Backend அந்த cash collection-ஐ தானாகவே record பண்ணும்
  (`DeliveryCashTransactionModel::recordCollection`, புது
  `cash_in_hand` balance-க்கு credit ஆகும்), order-ஓட `payment_status`-ஐ
  paid-ன்னு mark பண்ணும்.
- Wallet screen-ல இப்போ 2 tabs: **Earnings** (முன்பு மாதிரியே) மற்றும்
  **COD Cash** — partner தன்னோட cash-in-hand balance-ஐ பாத்து, "Remit
  Cash to Office" request போடலாம்.
- Remit request போட்ட உடனே balance குறையாது — அது `pending`-ஆ இருக்கும்,
  Admin panel-ல confirm பண்ணின பிறகுதான் balance குறையும்
  (**Admin → Cash Remittances**, `/admin/cash-remittances`) — partner
  "நான் cash கொடுத்துட்டேன்"-ன்னு சொன்னதே proof இல்ல, அதனால admin
  confirm பண்ணாத வரைக்கும் balance அப்படியே இருக்கும். Admin reason
  கொடுத்து reject-உம் பண்ணலாம்.
- புது migration (`20260905000001_CreateDeliveryCashTable`)
  `delivery_partners.cash_in_hand` + `delivery_cash_transactions` table
  create பண்ணும் — deploy பண்ணின உடனே **`php spark migrate` ரன்
  பண்ணணும்**.

**COD Cash tab-ல list காட்டலைன்னா** இதுல ஏதாவது ஒண்ணு காரணமா இருக்கலாம்:
1. Backend-ல புது code deploy ஆகி, `php spark migrate` ரன்
   பண்ணிருக்கணும் — இல்லனா `/delivery/cash` endpoint fail ஆகும்.
2. Phone-ல இருக்கிற APK **புது build இல்லன்னா** — இந்த feature
   சேர்க்கிறதுக்கு முன்னாடி build பண்ணின APK-ல இது இருக்காது; புதுசா
   build பண்ணி (CI workflow மூலமா) மறுபடியும் install பண்ணணும்.
3. இந்த feature வந்தப்புறம் ஒரு COD order கூட "delivered"-ஆ mark
   பண்ணல்லன்னா, list காலியா தான் இருக்கும் — இது bug இல்ல, சரியான
   behavior தான் (ஒரு test COD order deliver பண்ணி பாருங்க).

## தெரிஞ்சே விட்டு வச்சிருக்கிற இடங்கள் (Known gaps)

- **"Forgot Password?" மற்றும் "Terms & Conditions"** — placeholder
  தான். Forgot Password OTP login flow-க்கு தான் போகும் (தனி
  reset-password screen இல்ல). Terms & Conditions link ஒரு placeholder
  dialog-ஐ காட்டும் — இன்னும் real terms content எழுதல.
- **Earnings screen-ல "Tips" மற்றும் "Incentives" ₹0-ஆ காட்டும்.** இந்த
  codebase-ல tip/incentive கொடுக்கிற mechanism-ஏ இல்ல (customer app-லயும்
  driver-க்கு tip கொடுக்கிற feature இல்ல) — மாக்அப்-ஐ match பண்ண இந்த
  rows காட்டறோம், ஆனா value ஆனது கண்டுபிடிச்சு போடல, honest-ஆ zero.
  Real tipping feature வேணும்-ன்னா அது தனி வேலை.
- **Withdraw பண்ணா actual-ஆ பணம் போகாது.**
  `POST /delivery/wallet/withdraw` app-ல balance-ஐ குறைச்சு log
  பண்ணும், ஆனா bank-க்கு transfer பண்ற pipeline எதுவும் இல்ல — backend
  operate பண்றவர் manual-ஆ partner-க்கு பணம் அனுப்பணும்; pending
  withdrawals list பாக்க admin UI-உம் இன்னும் இல்ல.
- **Earnings calculation மாறிருக்கு** — partner earnings (dashboard,
  wallet credit) இப்போ order-ஓட `delivery_fee`-ஐ வெச்சு தான்
  கணக்கு போடுது, முழு order `total`-ஐ வெச்சு இல்ல. இது தான் சரியான
  கணக்கு, ஆனா பழைய dashboard numbers-உடன் compare பண்ணும்போது இதை
  ஞாபகம் வெச்சுக்குங்க.
- **Location tracking foreground-ல மட்டும்தான் வேலை செய்யும்** —
  background-ல ஓட ஒரு isolate/service setup இல்ல, அதனால delivery
  நடுவுல app background-க்கு போனா tracking நிக்கும்.
- **English மட்டும்தான்** — customer app மாதிரி Tamil localization
  இன்னும் இல்ல.
- **App icon placeholder** — தற்போது customer app-ஓட icon-ஐ reuse
  பண்றோம்; ship பண்ற முன்னாடி delivery-க்கான icon போடணும்.
- `dashboard()`-ல pending order broadcast, `is_available` flag-ஐ
  பொறுத்து filter ஆகாது (web dashboard-ஓட பழைய behavior இதே மாதிரி
  தான்) — offline ஆனா புது assignment நிக்கும், ஆனா ஏற்கனவே broadcast
  ஆன orders pending list-ல அப்படியே இருக்கும்.
- Settings, Help & Support — இரண்டும் placeholder screens (real
  settings/support channel இன்னும் இல்ல).
- Personal/Vehicle/Documents/Bank Details — **read-only** தான்; edit
  பண்ற update-profile endpoint இன்னும் இல்ல, அதனால எடிட் பண்ண backend
  operate பண்றவர் மூலமாதான் முடியும்.

## எப்படி run பண்றது

```
flutter pub get
flutter create --platforms=android --org com.jeevi .   # android/ folder generate ஆகும் (இது repo-ல commit ஆகாது)
flutter run
```

CI (`.github/workflows/build-apk.yml`) release APK build பண்ணும்,
optional Firebase setup-உடன் (`DELIVERY_GOOGLE_SERVICES_JSON_BASE64`
secret பத்தி workflow file-ல comments பாருங்க).
