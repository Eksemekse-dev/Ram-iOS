# RAM Test

iOS app that measures how much RAM it can fill before the system kills it.

## How it works

1. The **Test** tab shows how much RAM the app has filled.
2. The **Test** button starts filling memory and keeps going.
3. Progress is written to disk as fast as possible so the last value survives a crash.
4. After the app is killed and opened again, a popup shows how much RAM it managed to fill.

## IPA (GitHub Actions)

The `.github/workflows/build-ipa.yml` workflow builds an unsigned IPA on `macos-14`.

After a push to `main` (or **Actions → Build IPA → Run workflow**), download the `RAMTest.ipa` artifact.

An unsigned IPA will not install on a device until you sign it (Apple Developer, AltStore, Sideloadly). To sign in CI, add certificate and provisioning profile secrets.
