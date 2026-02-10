@attached(member, names: arbitrary)
public macro Changeable() =
  #externalMacro(
    module: "ChangeableMacros",
    type: "ChangeableFunctionMacro"
  )
