internal import MacroTestHelper
internal import SwiftSyntaxMacrosGenericTestSupport
internal import Testing

#if canImport(ChangeableMacros)
  import ChangeableMacros

  @Suite
  struct ChangeableDiagnosticsTests {
    @Test func classThrowsError() {
      MacroTestHelper.assertMacroExpansion(
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
      MacroTestHelper.assertMacroExpansion(
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
