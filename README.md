<p align="center">
  <img alt="logo" src="https://raw.githubusercontent.com/Rapid-SDK/android/master/extras/logo.png" />
</p>
<hr/>


<p align="center">
  <strong>iOS, macOS and tvOS client for <a href="https://www.rapidrealtime.com">Rapid</a></strong> realtime database 
</p>
<h3 align="center">
	<a href="https://www.rapidrealtime.com">
	  Website
	</a>
	<span> | </span>
	<a href="https://www.rapidrealtime.com/docs">
	  Documentation
	</a>
	<span> | </span>
	<a href="https://www.rapidrealtime.com/docs/api-reference-ios">
	  Reference
	</a>
</h3>

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Rapid.svg)](https://img.shields.io/cocoapods/v/Rapid.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/Rapid.svg?style=flat)](https://img.shields.io/cocoapods/p/Rapid.svg)


# What
Rapid is a cloud-hosted service that allows app developers to build realtime user interfaces without having to worry about the underlying infrastructure. It works as a non-relational data store accessible from a client-side code.


# Why
Clients can create, update, delete and subscribe to a set of data and receive updates in realtime.


# How

### Requirements

- iOS 8.0+
- macOS 10.10+
- tvOS 9.0+
- Xcode 9.0+
- Swift 4.0+

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build Rapid 1.0.0+.

To integrate Rapid iOS SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'Rapid'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Rapid SDK into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "rapid-io/rapid-io-ios"
```

Run `carthage update` to build the framework and drag the built `Rapid.framework` into your Xcode project.

### Manually

If you prefer not to use either of the dependency managers, you can either clone whole project or download the latest [iOS framework](Framework/iOS/Rapid.framework.zip), [macOS framework](Framework/Mac/Rapid.framework.zip) or [tvOS framework](Framework/tvOS/Rapid.framework.zip) and integrate Rapid SDK into your project manually.

## Caught a bug? 
Open an issue.

## License
[The MIT License](LICENSE)
