import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ChangeableFunctionMacro: MemberMacro {
  enum MacroDiagnostic: String, DiagnosticMessage {
    case requiresStruct = "#Changeable requires a struct"
    case requiresTypedStoredProperties = "#Changeable requires explicit type annotations on stored properties"

    var message: String { rawValue }

    var diagnosticID: MessageID {
      MessageID(domain: "Changeable", id: rawValue)
    }

    var severity: DiagnosticSeverity { .error }
  }

  public static func expansion(
    of attribute: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
      let diagnostic = Diagnostic(
        node: Syntax(attribute),
        message: MacroDiagnostic.requiresStruct
      )
      context.diagnose(diagnostic)
      throw DiagnosticsError(diagnostics: [diagnostic])
    }

    let bindings = structDeclaration.memberBlock.members
      .compactMap { $0.decl.as(VariableDeclSyntax.self) }
      .flatMap(\.bindings)

    // ignore computed properties
    let properties =
      bindings
      .filter { $0.accessorBlock == nil }

    guard properties.allSatisfy({ $0.typeAnnotation != nil }) else {
      let diagnostic = Diagnostic(
        node: Syntax(attribute),
        message: MacroDiagnostic.requiresTypedStoredProperties
      )
      context.diagnose(diagnostic)
      throw DiagnosticsError(diagnostics: [diagnostic])
    }

    let parameters =
      properties
      .map { binding in
        if binding.typeAnnotation!.type.is(OptionalTypeSyntax.self) {
          "\(binding.pattern): (() -> \(binding.type))? = nil"
        } else {
          "\(binding.pattern): \(binding.type)? = nil"
        }
      }
      .joined(separator: ",\n  ")

    let assignments = properties.map { binding in
      let pattern = binding.pattern

      return if binding.typeAnnotation!.type.is(OptionalTypeSyntax.self) {
        "\(pattern): \(pattern) != nil ? \(pattern)!() : self.\(pattern)"
      } else {
        "\(pattern): \(pattern) ?? self.\(pattern)"
      }
    }
    .joined(separator: ",\n    ")

    let withChangesDeclaration: DeclSyntax = """
      public func withChanges(
        \(raw: parameters)
      ) -> Self {
        Self(
          \(raw: assignments)
        )
      }
      """

    var result = [withChangesDeclaration]

    if let inheritanceClause = declaration.inheritanceClause,
      inheritanceClause.description.contains("Applicable")
    {
      let applicationAssignments = properties.map { binding in
        let pattern = binding.pattern

        return if binding.typeAnnotation!.type.is(OptionalTypeSyntax.self) {
          "\(pattern): path == \\Self.\(pattern) ? { value as? \(binding.type.replacingOccurrences(of: "?", with: "")) } : { \(pattern) }"
        } else {
          "\(pattern): path == \\Self.\(pattern) ? { value as! \(binding.type) }() : \(pattern)"
        }
      }
      .joined(separator: ",\n    ")

      let applyDeclaration: DeclSyntax = """
        public func apply(action: SetValue<Self, some Any>) -> Self {
          let path = action.path
          let value = action.value

          return withChanges(
            \(raw: applicationAssignments)
          )
        }
        """

      result.append(applyDeclaration)
    }

    return result
  }
}
