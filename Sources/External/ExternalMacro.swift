@attached(member, names: named(withChanges), named(apply))
public macro Changeable() =
  #externalMacro(
    module: "ChangeableMacros",
    type: "ChangeableFunctionMacro"
  )
