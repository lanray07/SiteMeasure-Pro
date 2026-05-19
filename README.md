# SiteMeasure Pro

SiteMeasure Pro is a SwiftUI iOS app for contractor site measurements, material and labor estimating, and client-ready proposal generation.

## Build Notes

- Minimum target: iOS 17.0
- Architecture: SwiftUI + MVVM + SwiftData
- Subscriptions: StoreKit 2 scaffold using placeholder product IDs
- AI: `MockAIService` is enabled by default; `RemoteAIService` posts to `https://YOUR_BACKEND_URL.com/site-measure-ai`
- Camera/photo: `PhotosPicker` plus camera capture wrapper
- PDF: Native `UIGraphicsPDFRenderer` proposal generation and share sheet
- Assets: generated app icon set, launch logo, onboarding hero, empty states, proposal preview, brand colors, and marketing exports

Configure real App Store Connect subscription products before release:

- `sitemeasure.pro.monthly`
- `sitemeasure.pro.yearly`
- `sitemeasure.business.monthly`

Do not place AI provider API keys in the iOS app. Proxy AI requests through your secure backend.

## Asset Generation

Run the asset generator from the repository root after changing the brand artwork:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Tools\GenerateAppAssets.ps1
```

Generated app assets live in `SiteMeasurePro/Resources/Assets.xcassets`. Exportable marketing files live in `MarketingAssets`.
