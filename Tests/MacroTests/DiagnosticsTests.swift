import MacroTester
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(ChangeableMacros)
  import ChangeableMacros

  @Suite struct ChangeableDiagnosticsTests {
    let testMacros: [String: Macro.Type] = [
      "Changeable": ChangeableFunctionMacro.self
    ]

    @Test func classThrowsError() {
      assertMacroExpansion(
        """
        @Changeable
        class AClass {
          let value: Int
          init(value: Int) { self.value = value }
        }
        """,
        expandedSource: """
          class AClass {
            let value: Int
            init(value: Int) { self.value = value }
          }
          """,
        diagnostics: [
          .init(
            message: ChangeableFunctionMacro.MacroDiagnostic.requiresStruct.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }

    @Test func untypedStoredPropertyThrowsError() {
      assertMacroExpansion(
        """
        @Changeable
        struct UntypedProperty {
          let value = 1
        }
        """,
        expandedSource: """
          struct UntypedProperty {
            let value = 1
          }
          """,
        diagnostics: [
          .init(
            message: ChangeableFunctionMacro.MacroDiagnostic.requiresTypedStoredProperties.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }
  }
#endif
