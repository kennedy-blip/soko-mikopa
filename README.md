# SokoMikopo

Offline-first Flutter (Dart) micro-loan ledger for borrowers, installments, partial repayments and arrears follow-up.

## Features
- Loan book, monthly flat-fee installment schedule, balance calculation and overdue status.
- Partial repayment log with Cash, M-Pesa, Bank or Other mode and transaction notes.
- Borrower search, Active / Overdue / Cleared filters and arrears watchlist.
- Local Hive persistence, JSON backup export, role switcher and three themes.
- Responsive Flutter UI, Vercel static web deployment and GitHub Actions APK release.

## Calculation policy
Total payable = principal × (1 + flat fee percentage / 100); installment = total payable ÷ number of monthly installments. This is a transparent recordkeeping calculation; confirm all agreed terms with borrowers. It is not a credit-scoring or lending decision system.

## Run locally
Install Flutter stable, then:
```bash
flutter create --platforms=android,web --project-name=soko_mikopo --org=ke.sokomikopo .
flutter pub get
flutter run -d chrome
```

## Vercel
Import the repository, set the root directory to the repository root, and deploy. `vercel.json` invokes `scripts/vercel-build.sh`, which installs Flutter if needed and writes the static site to `build/web`.

## Android APK
GitHub Actions runs `flutter analyze` and `flutter build apk --release` on pushes to main, then publishes the APK as a GitHub Release asset. The in-app APK link targets `https://github.com/kennedy-blip/soko-mikopa/releases/latest/download/SokoMikopo.apk`. Rename the uploaded workflow artifact to `SokoMikopo.apk` in a later release configuration if you change the asset filename.

## Data safety
Hive keeps records on the current device/browser origin. There is no cloud sync or server authentication. Role switching is a local workflow guard, not a security boundary; do not share an unlocked device between users with different permissions. Export backups regularly. Browser storage may be cleared by the user or browser.
