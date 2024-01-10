import Changeable

struct SetValue<State, T> {
  private init(path: AnyKeyPath, value: Any) {
    self.path = path
    self.value = value
  }

  let path: AnyKeyPath
  let value: Any

  static func with(keyPath: KeyPath<State, T>, value: T) -> SetValue<State, Any> {
    SetValue<State, Any>(path: keyPath, value: value as Any)
  }
}

@Changeable
struct State {
  let id: Int
  let name: String?
}

@Changeable
struct SecondState {
  let id: Int // in cm
  let name: String?
}

@Changeable
struct ThirdState {
  let id: Int // in cm
  let name: String? // comment
}
