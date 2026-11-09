# Release

## Version
- SemVer. `MARKETING_VERSION` in `SilverEdge.xcodeproj/project.pbxproj` has Debug and Release values; keep them equal.
  `CURRENT_PROJECT_VERSION` stays 1. Bump or commit only when asked.
- Before tagging: `make test`, `make lint`, `make build`, the CLT build, and a smoke test of both panels, the menu and themes.

## Signing
- Self-signed, not notarized: the `SilverEdge Self-Signed` identity in `~/Library/Keychains/silveredge-signing.keychain-db`
  (`make signing-identity`). Keep that keychain outside the repository; never publish its key or a keychain file.
- CI imports the same identity from the repository secrets `CERTIFICATE_P12_BASE64` (base64 `.p12` with certificate and key)
  and `CERTIFICATE_PASSWORD`. The workflow pins the certificate's public SHA-1 fingerprint; update it only when the identity changes.

## GitHub release
- `.github/workflows/release.yml` (macOS 26, Xcode 26.6): lint, tests, then separate `arm64` and `x86_64` Release builds,
  each checked for signature, certificate fingerprint, version, bundle identifier and architecture, zipped with a `.sha256`.
- Tag the checked-in version from `main`:
  ```sh
  git tag -a v1.0.0 -m "SilverEdge 1.0.0"
  git push origin v1.0.0
  ```
  A tag push creates a **draft** release with `SilverEdge-<version>-arm64.zip`, `-x86_64.zip` and their `.sha256` files.
  The tag must match the app version. Existing releases are never overwritten; delete a failed draft before retrying.
- Replace the draft notes with the release highlights, smoke-test a downloaded archive, then publish.
- **Actions → Release → Run workflow** builds a test run: Actions artifacts kept 14 days, no release.

## Developer ID later
`make release TEAM=<id> NOTARY_PROFILE=<profile>` archives, exports, notarizes and staples `build/SilverEdge.zip`.
Update the README's signing note when public builds become notarized.
