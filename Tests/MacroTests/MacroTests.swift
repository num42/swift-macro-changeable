import MacroTester
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(ChangeableMacros)
  import ChangeableMacros

  let testMacros: [String: Macro.Type] = [
    "Changeable": ChangeableFunctionMacro.self
  ]

  @Suite
  struct ChangeableFunctionMacroTests {
    @Test func changeable() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func changeableWithComment() {
      MacroTester.testMacro(macros: testMacros)
    }
  }
#endif
