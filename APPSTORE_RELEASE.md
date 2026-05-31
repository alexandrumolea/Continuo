# Continuo — App Store Release Checklist

Ghid pas-cu-pas pentru lansarea v1.0 pe App Store.

---

## ✅ Code & Configurație (deja făcut)

- [x] `PrivacyInfo.xcprivacy` — manifestul de privacy cerut de Apple din mai 2024
- [x] `ITSAppUsesNonExemptEncryption = false` în Info.plist (skip questionnaire criptare)
- [x] Entitlements curățate (doar HealthKit + Sign in with Apple)
- [x] Bundle ID: `GrowthCompany.Continuo`
- [x] Version: 1.0 / Build: 1
- [x] iOS deployment target: 26.0
- [x] Privacy Policy URL: `https://alexandrumolea.github.io/Continuo/`
- [x] Terms of Service URL: `https://alexandrumolea.github.io/Continuo/terms/`
- [x] Account deletion (in-app + web instructions)
- [x] Sign in with Apple cu token revocation
- [x] Welcome flow cu consent explicit (GDPR)

---

## 🔧 Pas 1 — Xcode (înainte de upload)

### 1.1 Adaugă PrivacyInfo.xcprivacy în proiect
Fișierul există pe disk dar trebuie inclus în Xcode project:

1. În Xcode → Project Navigator (panoul stânga)
2. Right-click pe folder-ul **Continuo** (cel cu icon galben, NU root-ul)
3. **Add Files to "Continuo"...**
4. Selectează `Continuo/PrivacyInfo.xcprivacy`
5. ✅ Bifează **Continuo** ca target → Add

### 1.2 Verifică Apple Developer signing
1. Project navigator → select **Continuo** (root proiect)
2. Tab **Signing & Capabilities**
3. **Team**: alege contul tău Apple Developer ($99/an)
4. **Bundle Identifier**: `GrowthCompany.Continuo` (sau schimbă-l dacă nu e disponibil)
5. **Automatically manage signing**: bifat (mai simplu pentru first release)

### 1.3 Verifică deployment target
Recomandat: **iOS 17.0** (mai mulți utilizatori, totuși API-uri moderne).
Tu ai acum **26.0** — extrem de restrictiv. Schimbă în Build Settings dacă vrei adopție mai mare.

```
Target Continuo → General → Minimum Deployments → iOS 17.0
```

### 1.4 App Icon
Verifică `Assets.xcassets/AppIcon.appiconset` are TOATE dimensiunile completate. Pentru iOS 18+ ai nevoie doar de **1024×1024** PNG (rest se generează automat din Xcode), dar verifică:
- Nu lăsa nicio dimensiune goală
- Fără transparență
- Fără colțuri rotunjite (Apple le aplică)
- Fără alpha channel

---

## 🌐 Pas 2 — App Store Connect (https://appstoreconnect.apple.com)

### 2.1 Creează app-ul
1. **My Apps** → **+** → **New App**
2. **Platform**: iOS
3. **Name**: `Continuo` (vizibil în App Store, 30 caractere max)
4. **Primary language**: English (U.S.)
5. **Bundle ID**: alege `GrowthCompany.Continuo` din dropdown
6. **SKU**: `continuo-ios-v1` (intern, nu se vede)
7. **User Access**: Full Access (sau Limited dacă ai echipă)

### 2.2 App Information

| Câmp | Valoare |
|---|---|
| **Subtitle** (30 chars) | `Your thread of growth` |
| **Category Primary** | Health & Fitness |
| **Category Secondary** | Lifestyle |
| **Content Rights** | Does NOT contain third-party content |
| **Age Rating** | Completați chestionarul → rezultat probabil 4+ |
| **Privacy Policy URL** | `https://alexandrumolea.github.io/Continuo/` |
| **Marketing URL** (opțional) | `https://alexandrumolea.github.io/Continuo/` |

### 2.3 Pricing
- **Price**: Free
- **Availability**: All countries (sau selectează doar EU/US dacă vrei pentru început)

---

## 📋 Pas 3 — App Privacy (chestionar)

În App Store Connect → App Privacy → Get Started. Răspunde:

### Do you or your third-party partners collect data?
✅ **Yes, we collect data**

### Data types collected:

| Data Type | Linked to user? | Used for tracking? | Purpose |
|---|---|---|---|
| **Email Address** | Yes | No | App Functionality |
| **Name** | Yes | No | App Functionality |
| **User ID** | Yes | No | App Functionality |
| **Other User Content** (reflections, goals, notes) | Yes | No | App Functionality |
| **Health & Fitness** (mindfulness minutes) | Yes | No | App Functionality |

❌ **NU** bifează: Advertising Data, Marketing, Analytics, Crash Data (nu folosim Crashlytics), Location, Contacts, Photos, Browsing History.

---

## 📸 Pas 4 — Screenshots

### Dimensiuni cerute de Apple (minim un set)

| Device | Resolution | Cerut? |
|---|---|---|
| **6.9" iPhone 16 Pro Max** | 1320 × 2868 | ✅ Recomandat (acoperă toate iPhone-urile) |
| **6.5" iPhone XS Max** | 1242 × 2688 | Opțional |
| **5.5" iPhone 8 Plus** | 1242 × 2208 | Opțional (legacy) |
| **iPad Pro 13"** | 2064 × 2752 | Doar dacă suporți iPad |

**Minim 3 screenshot-uri, maxim 10**. Recomandat 6-8.

### Cum să le faci rapid din Simulator
1. Xcode → Open Developer Tool → Simulator
2. Choose Device → **iPhone 16 Pro Max**
3. Run app cu Cmd+R
4. Navighează la ecranul dorit
5. **Cmd+S** salvează screenshot pe Desktop (cu numele "Simulator Screenshot — ...png")

### Cele 6 ecrane recomandate pentru Continuo

1. **Home** — cu daily practices + GP card (vinde "growth tracking")
2. **Mindfulness detail** — cu timer-ul + minutele de azi + HealthKit (vinde "mindfulness + Apple Health")
3. **Daily Practice (de ex. Activate Sage)** — cu prompts (vinde "reflection")
4. **Growth tab** — cu competencies + path to wisdom (vinde "progress")
5. **Coach Clients view** — cu lista de clienți + 3 acțiuni (vinde "coaching")
6. **Profile** — cu GP total + privacy + delete (vinde "transparency")

### Cum să le upload-ezi
- App Store Connect → versiunea ta → derulează la **Previews and Screenshots**
- Drag & drop fișierele .png direct în slot-uri

**Bonus**: poți folosi tools gratuite gen [Mockuuups](https://mockuuups.studio/) sau [Screenshots.pro](https://screenshots.pro/) să adaugi text de marketing peste screenshot-uri (ex. "Practice mindfulness daily" peste cel cu timer).

---

## 📝 Pas 5 — App Store copy (lipește direct)

### App Name
```
Continuo
```

### Subtitle (30 chars max)
```
Your thread of growth
```

### Promotional Text (170 chars, editabil oricând fără re-review)
```
Track your daily growth — reflections, goals, mindfulness, and coaching, all in one calm space. New: Apple Health sync for meditation minutes.
```

### Description (max 4000 chars)
```
Continuo is a calm, private space to track your personal growth journey — daily reflections, goals, mindfulness practice, and (optionally) sessions with a coach.

— DAILY PRACTICES —
Choose from prompts like "Activate Your Sage," "Today's Achievements," "Set Your Intention," "Releasing," and more. Earn Growth Points each time you reflect — a gentle nudge to keep showing up for yourself.

— MINDFULNESS WITH APPLE HEALTH —
Use the built-in meditation timer or log sessions manually. Every minute is synced both ways with Apple Health, so practice from any app (Calm, Apple Watch, anything else) counts toward your daily goal.

— GOALS & GROWTH PATH —
Set goals, capture reflections along the way, and watch your competencies — Inner Harmony, Self-Trust, Adaptability, Social Intelligence, Agency — grow over time.

— OPTIONAL COACHING —
If you work with a coach who also uses Continuo, connect with their unique code. Share specific reflections, log sessions together, and exchange assignments — all in one place. Coaches see only what you choose to share.

— PRIVACY FIRST —
Your reflections are yours. We never sell your data, never run ads, and never use what you write to train AI. You can delete your account and all data anytime from your profile.

Sign in with Apple, Google, or email/password. Free to use, with no in-app purchases.

Made with care in Romania.
```

### Keywords (100 chars max, comma-separated, no spaces after commas)
```
mindfulness,journal,coaching,growth,meditation,reflection,goals,daily,practice,wellness,timer
```

### Support URL
```
https://alexandrumolea.github.io/Continuo/
```

### Marketing URL (opțional)
```
https://alexandrumolea.github.io/Continuo/
```

### Copyright
```
© 2026 Alexandru Molea
```

### What's New (v1.0) — release notes
```
Welcome to Continuo — your thread of growth.

This is our first release. We're starting with:
• Daily reflection practices with prompts curated for personal growth
• Mindfulness timer + 2-way Apple Health sync
• Goals you can revisit and reflect on
• Five competencies that grow as you practice
• Optional coaching workflow (sessions, assignments, private notes)
• Sign in with Apple or Google, or email

Made with care in Romania. Tell us what you'd like next at alexandru.molea@bemore.ro.
```

---

## 🚀 Pas 6 — Build & Upload

### 6.1 Bump build number (înainte de fiecare upload nou)
În Xcode → target → General → **Build**: `1` (lasă) sau bumpează la `2`, `3` etc. la upload-uri ulterioare.

### 6.2 Archive
1. Xcode → top bar → device selector → alege **Any iOS Device (arm64)**
2. **Product** → **Archive** (durează 1-3 min)
3. Se deschide fereastra Organizer

### 6.3 Upload to App Store
1. În Organizer → selectează archive-ul nou → **Distribute App**
2. **App Store Connect** → Next
3. **Upload** → Next
4. Lasă opțiunile default: ✅ Strip Swift symbols, ✅ Upload symbols, ✅ Manage version
5. **Automatically manage signing** → Next
6. Review → **Upload**
7. Așteaptă ~2-5 min să apară în App Store Connect (poți primi un email cu "Build is processing")

### 6.4 TestFlight (RECOMANDAT înainte de submission publică)
1. App Store Connect → app-ul tău → **TestFlight** tab
2. După ce build-ul e procesat, completează **Test Information** (descrierea pentru tester)
3. **Internal Testing** → adaugă-te pe tine + max 100 colegi (instant access)
4. **External Testing** (opțional) — necesită un mic review de la Apple (1-2 zile)
5. Testează 1-2 zile, fixa bug-uri, re-upload dacă e nevoie

---

## 📤 Pas 7 — Submit for Review

1. App Store Connect → app-ul tău → **App Store** tab (sus, lângă TestFlight)
2. **iOS App 1.0** → completează toate secțiunile (sunt în warning galben dacă lipsesc)
3. La **Build** → click + → alege build-ul uploadat
4. **App Review Information**:
   - **Contact**: numele tău + email + telefon (folosit doar dacă au întrebări)
   - **Demo account**: 
     ```
     Email: demo@continuo.app
     Password: ContinuoDemo2026!
     ```
     (creează contul ăsta înainte! Apple îl folosește să testeze)
   - **Notes**: 
     ```
     Continuo is a personal growth journaling app with optional coaching. 
     The demo account is set up as a Client. To test the Coach workflow, 
     please create a new account and select "Coach" in the welcome setup.
     
     HealthKit usage: read & write mindful sessions (read existing minutes 
     from other apps, write user-logged sessions). All HealthKit access is 
     on-demand when user opens the Mindfulness screen — no background queries.
     
     Sign in with Apple: implemented with proper token revocation on account 
     deletion (as required by 5.1.1(v)).
     ```
5. **Version Release**:
   - ✅ **Manually release this version** (recomandat pentru first release — poți alege când să iasă)
6. **Submit for Review**

⏱️ Review-ul durează tipic **24-48h**. Poate fi mai lung pentru first submission.

---

## 🚨 Common rejection reasons & cum le eviți

### 1. "We discovered bugs in your app"
**Soluție**: testează ALL paths în Simulator înainte de submission. Cele mai uitate: sign out + sign back in, delete account, no internet.

### 2. "Privacy policy doesn't match app behavior"
**Soluție**: ai deja policy detaliat care menționează exact ce colectezi. Verifică să nu fi promis ceva în descriere ce nu faci (ex. "exports to PDF" dacă nu există).

### 3. "Account deletion not found"
**Soluție**: tu ai Profile → Delete account. Menționează asta în review notes.

### 4. "Apple Sign In token revocation missing"
**Soluție**: ai deja `revokeToken` în `deleteAccount`. Menționează în review notes.

### 5. "App crashes on launch"
**Soluție**: TestFlight build pe device real înainte. Dacă crash, vezi logs cu Console.app.

### 6. "Unclear coach-client model"
**Soluție**: în review notes spune că app-ul nu pretinde să verifice credentialele coach-ilor — e doar un instrument de organizare.

---

## 📊 După aprobare

- **Manual release**: app-ul rămâne "Pending Developer Release" — tu apeși **Release This Version** când vrei să apară public
- **Phased Release**: setează în App Store Connect pentru rollout treptat (7 zile) — siguranță în plus
- **Monitor**: App Store Connect → **Analytics** după primele 24h să vezi instalări + retenție

---

## 🔄 Update-uri viitoare

Pentru v1.0.1, v1.1 etc.:
1. Schimbă `MARKETING_VERSION` în Xcode Build Settings
2. Bumpează `CURRENT_PROJECT_VERSION` 
3. App Store Connect → **+ Version or Platform** → introdu noua versiune
4. Completează **What's New** (max 4000 chars)
5. Upload nou build → submit

---

**Contact pentru orice problemă la review**: Apple Developer Support, sau în App Store Connect → Resolution Center (dacă apare un mesaj de la reviewer).

Mult succes la launch! 🚀
