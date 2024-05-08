import ChangeableMacros
import MacroTester
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

let testMacros: [String: Macro.Type] = [
    "Changeable": ChangeableFunctionMacro.self,
]

final class ChangeableFunctionMacroTests: XCTestCase {
    func testChangeable() {
        testMacro(macros: testMacros)
    }

    func testChangeableWithComment() {
        testMacro(macros: testMacros)
    }
}
