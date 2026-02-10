internal import SwiftCompilerPlugin
internal import SwiftSyntaxMacros

@main
struct ChangeablePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ChangeableFunctionMacro.self
  ]
}
