# Changeable

`@Changeable` is a Swift macro that generates ergonomic copy-updating helpers for structs.

What you get:
- `withChanges(...)` to produce a modified copy.
- `apply(action:)` when the type conforms to `Applicable`.

## Requirements

- Swift 6.2 toolchain (macro support)
- Platforms: macOS 13, iOS 13, tvOS 13, watchOS 6, macCatalyst 13

## Installation

Add this package to your SwiftPM dependencies and import `Changeable` in the files where you use the macro.

## Basic Usage

```swift
import Changeable

@Changeable
struct Profile {
  let name: String
  let age: Int
}

let profile = Profile(name: "Pat", age: 30)
let updated = profile.withChanges(name: "New Name")
```

Generated:

```swift
public func withChanges(
  name: String? = nil,
  age: Int? = nil
) -> Self {
  Self(
    name: name ?? self.name,
    age: age ?? self.age
  )
}
```

## Optional Properties

To allow setting an optional to `nil`, the macro uses a closure wrapper for optional properties.

```swift
@Changeable
struct Settings {
  let nickname: String?
}

let settings = Settings(nickname: "Pat")
let cleared = settings.withChanges(nickname: { nil })
```

Generated:

```swift
public func withChanges(
  nickname: (() -> String?)? = nil
) -> Self {
  Self(
    nickname: nickname != nil ? nickname!() : self.nickname
  )
}
```

## `Applicable` Integration

If your struct already conforms to `Applicable`, `@Changeable` also generates:

```swift
public func apply(action: SetValue<Self, some Any>) -> Self
```

This is intended for codebases that route mutations through a `SetValue` action and `Applicable` protocol.

## Constraints

- Apply the macro to a `struct` only.
- Only stored properties are considered (computed properties are ignored).
- Stored properties must have explicit type annotations.
