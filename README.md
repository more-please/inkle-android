# Android-specific code for Sorcery! and 80 Days

This is the common code for my Android ports of inkle's iOS games, [Sorcery!](https://www.inklestudios.com/sorcery/) and [80 Days](https://www.inklestudios.com/80days/). As described in [inkle's blogpost](https://www.inklestudios.com/2014/03/11/tech-focus-android.html), I decided to compile their Objective-C code directly for Android, and built my own UIKit emulation layer using OpenGL ES. Later on I used the same codebase to make Mac and Windows builds (using SDL) for the Steam store.

Please note that:

- This is _not_ a complete working game;
- It's not general-purpose code; it only does the minimum needed to support those games;
- The code is untidy and poorly documented.

Nevertheless, it could still be useful if you're interested in how the UIKit emulation worked (or maybe as a point of reference if you're building your own).

## Architecture

The bulk of the code is almost ten years old, so it's not fully up to date with the latest APIs on either iOS or Android. We have been maintaining the games on both platforms, though, so everything should still work. Most recently, I updated all the games to work with Android API level 33, Google's new minimum requirement for the Play Store.

When bootstrapping this codebase, I started on iOS and gradually converted the UIKit code to use a custom OpenGL layer. Underneath that, the _real_ UIKit was still there; I called my emulation layer "APKit" (Android Port) to avoid name clashes, and used macros to redirect the game code.

When I finally got it running on Android, I never fully removed this two-layer structure; so confusingly, there are _two_ UIKit layers in this code. `APKit` is the real UIKit emulator that the game talks to; `APCore/UIKit` emulates the iOS host environment. This may help explain some of the [strange code](https://github.com/more-please/inkle-android/blob/899b622b289ca83355e7c320fabe353f2f708d42/APKit/src/APKit_main.mm#L1163) and apologetic comments. 😅

A lot of the code is written to support very low-end GPUs. For example, inkle's games make heavy use of large images with alpha channels, which many Android phones struggled with 10 years ago. Therefore, I render images in multiple horizontal strips, so we can a) assemble them into power-of-two sized texture atlases; and b) minimise the number of fully-transparent pixels that need to be drawn. This gave decent performance at the time, but seriously complicates the code, and isn't necessary or desirable today.

`.mm` files are Objective-C++. This sounds like a Frankenstein nightmare of a language, but I found it incredibly useful to bridge between inkle's Objective-C code and the Android platform (which uses C/C++). I generally used C++ when adding my own utilities.

I went through a number of build systems and wasn't happy with any of them. The games currently use a custom Python-based build script generating [Ninja](https://ninja-build.org) files (not included). If there's any interest in building a working example with this repo, let me know.

## Project structure

- `APCore`: mostly contains header files for various iOS frameworks (and a few implementation stubs). Header definitions are generally copied from Xcode headers; implementations are my own. (There are comments in the source or in git commits where I've referenced code from the web.)
- `APKit`: the main UIKit (and GLKit) emulation layer.
  - Most modules are direct re-implementations of iOS modules, e.g. `AP_Image` re-implements `UIImage`.
  - Some are my own additions, e.g. `AP_WeakCache`
  - `APKit_main.mm` contains the startup code, main rendering loop, and interface with the Java code (not included here).
- `assets` and `icons`: miscellaneous small UI assets.
- `include` and `lib`: common code used by multiple utilities and/or shared with the game itself.
- `more-tools`: miscellaneous C/C++ utilities; an unsuccessful attempt to tidy up `tools` to make it suitable for open sourcing.
  - `stb` is not my code, it's Sean Barrett's indispensable [single-file public domain libraries](https://github.com/nothings/stb) which I use extensively in this repo. I don't recall why I ended up vendoring it here.
- `tools`: various command-line tools used in the game build pipelines, mostly involving processing images in various ways. A few notable ones:
  - `fontex` processes font files (using `stb_truetype`) and generates texture atlases.
  - `pak` combines assets into a flat file.
  - `repak` is a later addition used to generate patch files.
- `Makefile`: this just builds `tools`, not the whole game.
