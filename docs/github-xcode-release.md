# GitHub Xcode Release Workflow

Use GitHub Actions for Xcode builds and App Store Connect uploads. This keeps the Windows workspace focused on code changes while GitHub macOS runners perform Xcode archive/sign/upload work.

## Required Repository Secrets

Add these in GitHub under Settings > Secrets and variables > Actions > Repository secrets:

- `APP_STORE_CONNECT_KEY_ID`: App Store Connect API key ID.
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect issuer ID.
- `APP_STORE_CONNECT_API_KEY_BASE64`: Base64-encoded contents of the `AuthKey_<KEY_ID>.p8` file.
- `APPLE_TEAM_ID`: Apple Developer Team ID, the 10-character team identifier used for code signing.
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64`: Base64-encoded Apple Distribution `.p12` certificate.
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`: Password for the Apple Distribution `.p12` certificate.
- `IOS_APP_STORE_PROFILE_BASE64`: Base64-encoded App Store provisioning profile for `com.lanray07.sitemeasurepro`.
- `SIGNING_KEYCHAIN_PASSWORD`: Random password for the temporary CI keychain.

Create the API key in App Store Connect under Users and Access > Integrations > App Store Connect API. Use a role that can manage apps and upload builds.

## Encode the API Key

On macOS:

```bash
base64 -i AuthKey_<KEY_ID>.p8 | pbcopy
```

On Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_<KEY_ID>.p8")) | Set-Clipboard
```

Paste the copied value into the `APP_STORE_CONNECT_API_KEY_BASE64` secret.

The App Store upload job uses manual signing in CI. The SiteMeasure profile should be an `IOS_APP_STORE` provisioning profile tied to the `com.lanray07.sitemeasurepro` bundle ID and an Apple Distribution certificate whose private key is included in the `.p12`.

## Running the Workflow

The workflow file is `.github/workflows/ios-xcode.yml`.

- Pushes and pull requests run an unsigned iOS Simulator build.
- Manual runs archive, export, and upload an IPA to App Store Connect on the `macos-26` runner with a stable Xcode 26 toolchain selected, which is required for current App Store uploads. If the runner image has Xcode 26 without the iOS platform installed, the workflow downloads the iOS platform before archiving.

To upload a build:

1. Open GitHub Actions.
2. Select `iOS Xcode`.
3. Choose `Run workflow`.
4. Set `upload_to_app_store` to `true`.
5. Optionally enter a build number. If blank, GitHub uses the workflow run number.

After the upload finishes, App Store Connect may take several minutes to process the build. Select the processed build on the iOS version page, answer any build-level compliance prompts, attach the first subscription if required, and submit for review.

## App Settings

- Xcode project: `SiteMeasurePro.xcodeproj`
- Scheme: `SiteMeasurePro`
- Bundle ID: `com.lanray07.sitemeasurepro`
- Export method: automatically chooses `app-store-connect` when the runner Xcode supports it, otherwise falls back to `app-store`.

Do not commit Apple private keys, certificates, provisioning profiles, or AI provider API keys to the repository.
