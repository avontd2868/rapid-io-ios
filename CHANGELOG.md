# Change Log
All notable changes to this project will be documented in this file.

#### 1.x Releases
- `1.2.x` Releases - [1.2.0](#120) | [1.2.1](#121)
- `1.1.x` Releases - [1.1.0](#110) | [1.1.1](#111) | [1.1.2](#112)
- `1.0.x` Releases - [1.0.0](#100) | [1.0.1](#101) | [1.0.2](#102)

---

## [1.2.1](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.2.1)
Released on 2017-10-17.

#### Added

- Deserialize `RapidDocument`s from subscriptions and fetches directly into objects that conform to Decodable protocol

- Mutate and merge documents with objects that conform to Encodable protocol

- Implement support for encoding/decoding customizations

#### Updated

- Convert classes into structures

- Change subscription filter implementation

---

## [1.2.0](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.2.0)
Released on 2017-09-18.

#### Added

- Swift 4

- Deserialize `RapidDocument` to an object that conforms to Codable

#### Updated

- Simplify example chat app

---

## [1.1.2](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.1.2)
Released on 2017-08-22.

#### Added

- Modify document on connect/disconnect

- Cancel write requests

#### Updated

- Crash SDK when the shared singleton is configured with an invalid API key

#### Fixed

- Handling connection status

---

## [1.1.1](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.1.1)
Released on 2017-07-17.

#### Added

- Chat example

- Get server time offset

#### Updated

- Common protocol for subscription and fetch references

- Implement request timeout as an instance variable
  - Request timeout used to be a static variable of `Rapid` class

#### Fixed

- Testability for prebuilt frameworks

---

## [1.1.0](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.1.0)
Released on 2017-06-22.

#### Added

- Support tvOS

#### Updated

- Channel reference implementation
  - You can check up-to-date implementation [here](https://rapid-io.github.io/rapid-io-ios/Classes.html)

- Execution block signature
  - You can check up-to-date implementation [here](https://rapid-io.github.io/rapid-io-ios/Typealiases.html#/s:5Rapid19RapidExecutionBlock)

---

## [1.0.2](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.0.2)
Released on 2017-06-08.

#### Fixed
- Connection request http headers

---

## [1.0.1](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.0.1)
Released on 2017-06-07.

#### Added
- Secured connection

#### Fixed
- Example project dependencies

---

## [1.0.0](https://github.com/rapid-io/rapid-io-ios/releases/tag/1.0.0)
Released on 2017-06-02

#### Added

- Connect to Rapid database
- Subscribe to changes
- Mutate database
- Authenticate
- Optimistic concurrency
