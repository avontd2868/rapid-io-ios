# Change Log
All notable changes to this project will be documented in this file.

#### 1.x Releases
- `1.1.x` Releases - [1.1.0](#110)
- `1.0.x` Releases - [1.0.0](#100) | [1.0.1](#101) | [1.0.2](#102)

---

## [4.5.0](https://github.com/Alamofire/Alamofire/releases/tag/4.5.0)
Released on 2017-06-16. All issues associated with this milestone can be found using this
[filter](https://github.com/Alamofire/Alamofire/issues?utf8=✓&q=milestone%3A4.5.0).

#### Added
- Missing `@escaping` annotation for session delegate closures.
  - Added by [Alexey Aleshkov](https://github.com/djmadcat) in Pull Request
  [#1951](https://github.com/Alamofire/Alamofire/pull/1951).
- New `mapError`, `flatMapError`, `withValue`, `withError`, `ifSuccess`, and `ifFailure` APIs to `Result`.
  - Added by [Jon Shier](https://github.com/jshier) in Pull Request
  [#2135](https://github.com/Alamofire/Alamofire/pull/2135).

#### Updated
- The Travis config file to Xcode 8.3.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request
  [#2059](https://github.com/Alamofire/Alamofire/pull/2059).
- Response serialization implementation to use separate internal variable.
  - Updated by [Eunju Amy Sohn](https://github.com/EJSohn) in Pull Request
  [#2125](https://github.com/Alamofire/Alamofire/pull/2125).
- `SessionDelegate` internal implementation by removing redundant optional unwrap.
  - Updated by [Boris Dušek](https://github.com/dusek) in Pull Request
  [#2056](https://github.com/Alamofire/Alamofire/pull/2056).
- The `debugPrintable` implementation of `Request` to use `curl -v` instead of `curl -i` to be more verbose.
  - Updated by [Simon Warta](https://github.com/webmaster128) in Pull Request
  [#2070](https://github.com/Alamofire/Alamofire/pull/2070).
- The `MultipartFormData` contentType property to be mutable.
  - Updated by [Eric Desa](https://github.com/ericdesa) in Pull Request
  [#2072](https://github.com/Alamofire/Alamofire/pull/2072).
- Travis CI yaml file to enable watchOS 3.2 builds.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request
  [#2135](https://github.com/Alamofire/Alamofire/pull/2135).
- Alamofire to build with Xcode 9 with Swift 3.2 and 4.0 in addition to Xcode 8.3 and Swift 3.1.
  - Updated by [Jon Shier](https://github.com/jshier) in Pull Request
  [#2163](https://github.com/Alamofire/Alamofire/pull/2163).

#### Removed
- Custom string extension no longer needed in the test suite.
  - Removed by [Nicholas Maccharoli](https://github.com/Nirma) in Pull Request
  [#1994](https://github.com/Alamofire/Alamofire/pull/1994).

#### Fixed
- Issue in the `URLProtocolTestCase` where HTTP header capitalization was wrong due to httpbin.org change.
  - Fixed by [Natascha Fadeeva](https://github.com/Tanaschita) in Pull Request
  [#2025](https://github.com/Alamofire/Alamofire/pull/2025).
- Issues and typos throughout the README documentation and sample code and source code docstrings.
  - Fixed by
  [Raphael R.](https://github.com/reitzig),
  [helloyako](https://github.com/helloyako),
  [DongHyuk Kim](https://github.com/sss989870),
  [Bas Broek](https://github.com/BasThomas),
  [Jorge Lucena](https://github.com/jorgifumi),
  [MasahitoMizogaki](https://github.com/MMizogaki),
  [José Manuel Sánchez](https://github.com/buscarini),
  [SabinLee](https://github.com/SabinLee),
  [Mat Trudel](https://github.com/mtrudel),
  [Wolfgang Lutz](https://github.com/Lutzifer), and
  [Christian Noon](https://github.com/cnoon) in Pull Requests
  [#1995](https://github.com/Alamofire/Alamofire/pull/1995),
  [#1997](https://github.com/Alamofire/Alamofire/pull/1997),
  [#1998](https://github.com/Alamofire/Alamofire/pull/1998),
  [#2022](https://github.com/Alamofire/Alamofire/pull/2022),
  [#2031](https://github.com/Alamofire/Alamofire/pull/2031),
  [#2035](https://github.com/Alamofire/Alamofire/pull/2035),
  [#2080](https://github.com/Alamofire/Alamofire/pull/2080),
  [#2081](https://github.com/Alamofire/Alamofire/pull/2081),
  [#2092](https://github.com/Alamofire/Alamofire/pull/2092),
  [#2095](https://github.com/Alamofire/Alamofire/pull/2095),
  [#2104](https://github.com/Alamofire/Alamofire/pull/2104).
- Several warnings in the test suite related to Xcode 8.3.
  - Fixed by [Jon Shier](https://github.com/jshier) in Pull Request
  [#2057](https://github.com/Alamofire/Alamofire/pull/2057).
- Issue where reachability calculation incorrectly reported `.reachable` status with [`.connectionRequired`, `.isWWAN`] combination.
  - Fixed by [Marco Santarossa](https://github.com/MarcoSantarossa) in Pull Request
  [#2060](https://github.com/Alamofire/Alamofire/pull/2060).

---

## [1.0.0](https://github.com/rapid-io/ios/releases/tag/1.0.0)

#### Added

