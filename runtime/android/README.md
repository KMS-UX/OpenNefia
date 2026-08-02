# Android build path (prototype)

**Status: build pipeline proven, boot still broken.** A debug-signed,
installable APK builds successfully from this repo's `src/` and installs
fine (`aapt2 dump badging` + `apksigner verify` both pass — package
`com.quantumeffect.prototype`, label "Quantum Effect"). Running it on an
emulator crashes during Lua module loading — see
[Known gaps](#known-gaps-not-addressed-by-this-prototype), first item, for
what's actually going on and what's still needed.

This is a first working path to an installable Android build of OpenNefia,
using LÖVE's official Android port ([love2d/love-android](https://github.com/love2d/love-android))
rather than a rewrite. It packages `src/` into a `.love` file and embeds it
into a love-android build, same as any other LÖVE-for-Android game.

The engine already has some Android-specific handling in place
(`src/boot.lua`, `src/api/Draw.lua`), so this is closer to "finish wiring up
an existing target" than "add mobile support from scratch."

## One-time setup

1. Install **Android Studio**.
2. In Android Studio → SDK Manager → SDK Tools, tick "Show Package Details"
   and install **NDK (Side by Side) 25.2.9519653**, and SDK Platform **34**.
   (Alternatively use the `cmdline-tools`' `sdkmanager` to install
   `ndk;25.2.9519653` and `platforms;android-34` non-interactively.)
3. Set the `ANDROID_SDK_ROOT` environment variable to your SDK location
   (Android Studio shows this under SDK Manager → Android SDK Location).
4. **Get a standalone JDK 17.** love-android's pinned Gradle wrapper (8.1)
   cannot run under newer JDKs — as of writing, current Android Studio
   releases bundle JDK 25 in their JBR, which fails the build with `BUG!
   exception in phase 'semantic analysis' ... Unsupported class file major
   version 69`. The bundled-JDK-17 assumption in love-android's own README is
   out of date; download a JDK 17 build yourself, e.g.
   [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17)
   for Windows x64, and set `JAVA_HOME_17` to its extracted path — the build
   scripts here pick it up automatically (see below).
5. Clone love-android next to this repo (or anywhere; point `LOVE_ANDROID_DIR`
   at it):

   ```
   git clone --recurse-submodules -b 11.5a https://github.com/love2d/love-android
   ```

   The `-b 11.5a` pins the version that matches what this project has been
   tested against. `conf.lua` currently declares `t.version = "11.3"`, but
   11.5 boots the game fine — no need to hunt for an older tag.

## Building

From this repo's root:

```
set LOVE_ANDROID_DIR=C:\path\to\love-android
set JAVA_HOME_17=C:\path\to\jdk-17
runtime\android\build_apk.bat
```

(or `runtime/android/build_apk` on macOS/Linux, if `LOVE_ANDROID_DIR` isn't
a sibling directory named `love-android`. `JAVA_HOME_17` is only needed if
your default `JAVA_HOME`/Android Studio JBR is newer than 17 — see setup
step 4 above.)

This packages `src/` into a `.love`, drops it into
`app/src/embed/assets/game.love` inside the love-android checkout, and runs
`gradlew assembleEmbedNoRecordDebug`. The debug variant is auto-signed with
a debug key by Gradle, so the resulting APK installs directly — no manual
`jarsigner`/`zipalign` step needed for this prototype stage.

Output APK:

```
<LOVE_ANDROID_DIR>\app\build\outputs\apk\embedNoRecord\debug\app-embed-noRecord-debug.apk
```

Install to a connected device/emulator with `adb install -r <path to apk>`.

## App identity

`<LOVE_ANDROID_DIR>/gradle.properties` has been pre-filled with placeholder
Quantum Effect identity:

```
app.name=Quantum Effect
app.application_id=com.quantumeffect.prototype   # placeholder — change before any real release
app.version_code=1
app.version_name=0.1.0-prototype
```

`app.application_id` is permanent once published to an app store — replace
it with a real reverse-domain id you control before distributing this
anywhere beyond your own devices.

## Known gaps (not addressed by this prototype)

- **Lua module loading crashes on boot (unresolved).** Tested on an emulator
  (API 34, x86_64): the app installs and launches but immediately crashes
  with `boot.lua:48: module 'ext' not found`.

  `src/boot.lua` has an Android-specific workaround (the `if
  love.system.getOS() == "Android"` block) that rewrites `package.path`
  entries like `./?.lua` into OS-absolute paths using
  `love.filesystem.getSource()`, on the theory that LÖVE's require
  machinery needs real filesystem paths on Android. One bug in that
  rewrite was fixed here — the original code concatenated
  `getSource()` directly against `?.lua` with no path separator, producing
  paths like `.../game.loveext.lua`. That's fixed (see the `boot.lua` diff
  in this change), and path formation is now correct:
  `.../cache/game.love/ext/init.lua`.

  But it still fails, because that whole premise doesn't hold on current
  love-android (11.5a): the game isn't extracted to a real folder on disk —
  logcat shows `GameActivity: Successfully copied stream to
  .../cache/game.love (N bytes written)`, i.e. `game.love` is mounted as a
  packed archive via PhysFS, not unpacked. `getSource()` returns a path
  *to* that archive, not a real directory you can concatenate module paths
  onto and read via `io.open`/`loadfile` — and `love.filesystem.load`
  (LÖVE's own sandboxed loader, which *should* be able to read into the
  mounted archive) expects paths relative to the game's virtual root, not
  OS-absolute strings like the ones this code constructs. So neither of
  the two loaders in play can currently resolve modules on Android.

  This needs someone to actually work through LÖVE's require-path /
  `love.filesystem.setRequirePath` / PhysFS semantics rather than another
  guess at path string surgery — worth checking how other actively
  LÖVE-for-Android-shipped games handle this (`require` might just work
  unmodified on 11.5a and this whole workaround needs removing, given it
  predates the current love-android version), or asking upstream
  (love-android's issue tracker / Discord).

- **Game assets.** `src/game/startup.lua` copies sprite/sound assets from
  `src/deps/elona` (the original Elona 1.22 freeware, fetched by
  `runtime/setup.bat`) into the game's own asset folders on first run. That
  folder isn't present by default, and the packaged `.love` here does not
  include it — the app currently gets as far as the license/version-check
  crash you'd also see running the desktop build without deps set up. This
  is an asset-pipeline decision (bundle assets into the `.love` vs. some
  on-device fetch flow) that's separate from the build-path question this
  prototype answers, and needs its own call before this is playable.
- **Touch input / mobile UI.** The UI layer stack was built for keyboard
  and mouse. No touch controls have been added.
- **Release signing.** This build path produces a debug-signed APK only.
  A real release needs a proper keystore and the `assembleEmbedNoRecordRelease`
  / `bundleEmbedNoRecordRelease` targets (see love-android's
  [Game Packaging wiki](https://github.com/love2d/love-android/wiki/Game-Packaging)).
