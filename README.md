<div align="center">
  <img src="https://raw.githubusercontent.com/LiveEnhancementSuite/LESforMacOS/develop/Hammerspoon/Images.xcassets/AppIcon.appiconset/icon_256x256.png" alt="Live Enhancement Suite"/>
  <br/>
  <a href="https://github.com/LiveEnhancementSuite/LESforMacOS/tree/develop">
    <img src="https://github.com/LiveEnhancementSuite/LESforMacOS/actions/workflows/les_build.yml/badge.svg" alt="Build Status">
  </a>
  <br/>
</div>

LESforMacOS is the macOS version of the Live Enhancement Suite. It is a fork of [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) that embeds [Lua scripts](https://github.com/LiveEnhancementSuite/LESforMacOS/tree/develop/extensions/les) that leverage Hammerspoon to provide easy-to-use shortcuts and macros to provide quality of life improvements that enhance your Ableton Live experience.

## Getting Started

 * Download the [latest release](https://github.com/LiveEnhancementSuite/LESforMacOS/releases/latest)
 * Open `Live Enhancement Suite.dmg` and follow the prompted instructions
 * Visit our [documentation](https://docs.enhancementsuite.me/) to learn how you can get the best out of LESforMacOS.

### Minimum requirements

LESforMacOS requires at least macOS 11 (Big Sur) and Ableton Live 10.

## Building LESforMacOS

You will require at least Xcode 14.1 (available with an Apple Developer account), Homebrew, Cocoapods and Ruby 3.x installed.
After that, you can install the dependencies needed to build LESforMacOS.

* Install dependencies from Homebrew
  ```bash
  brew install coreutils jq xcbeautify gawk gh gpg
  ```

* Install Ruby dependencies with `gem`
  ```
  gem install --user t
  gem install trainer
  ```

Once you have installed the base dependencies, you can clone the repo and install the CocoaPods and Python dependencies.

* Clone the repository
  ```bash
  git clone https://github.com/LiveEnhancementSuite/LESforMacOS
  cd LESforMacOS
  ```

* Install CocoaPods dependencies
  ```bash
  pod install
  ```

* Install Python dependencies
  ```bash
  pip3 install --user -r requirements.txt
  ```

* Build LESforMacOS
  ```bash
  XCODE_ARGS="GCC_TREAT_WARNINGS_AS_ERRORS=NO MACOSX_DEPLOYMENT_TARGET=11.0"
  xcodebuild -workspace Hammerspoon.xcworkspace -scheme Hammerspoon -configuration Debug ${XCODE_ARGS} clean build | xcbeautify
  ```

## Contributing to LESforMacOS

To contribute to LESforMacOS, you can either contribute to the Hammerspoon fork or to the scripts that make up LESforMacOS. This portion will be covering contributions to the underlying scripts.

For existing Hammerspoon users, think of it as a `~/.hammerspoon` embedded into the application bundle itself. 

LESforMacOS stores its configuration files and jumpstart script (i.e. an `init.lua` script that redirects the Hammerspoon core to execute logic from within the application bundle) in `~/.les` but the core logic resides in `Contents/Resources/extensions/hs/les`.

In the source tree, this is equivalent to `extensions/les`.

## About

```
Copyright (c) 1994 - 2017 Lua.org, PUC-Rio
Copyright (c) 2014 - 2023 The Hammerspoon Contributors[1]
Copyright (c) 2019 - 2023 LESforMacOS authors[2]

Released under the MIT License.

[1] - https://github.com/Hammerspoon/hammerspoon/graphs/contributors
[2] - https://github.com/LiveEnhancementSuite/LESforMacOS/blob/develop/extensions/les/AUTHORS.txt
```
