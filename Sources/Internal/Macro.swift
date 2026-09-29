internal import MacroHelper
public import SwiftDiagnostics
public import SwiftSyntax
public import SwiftSyntaxMacros

public struct ChangeableFunctionMacro: MemberMacro {
  public enum MacroDiagnostic: String, DiagnosticMessage {
    case requiresStruct = "@Changeable requires a struct"
    case requiresTypedStoredProperties =
      "@Changeable requires explicit type annotations on stored properties"

    public var message: String { rawValue }

    public var diagnosticID: MessageID {
      MessageID(domain: "Changeable", id: rawValue)
    }

    public var severity: DiagnosticSeverity { .error }
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
      throw DiagnosticsError(diagnostics: [diagnostic])
    }

    let bindings = structDeclaration.storedPropertyBindings(includingStatic: true)

    // ignore computed properties
    let properties =
      bindings
      .filter { $0.accessorBlock == nil }

    guard properties.allSatisfy({ $0.typeAnnotation != nil }) else {
      let diagnostic = Diagnostic(
        node: Syntax(attribute),
        message: MacroDiagnostic.requiresTypedStoredProperties
      )
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
      let applicationCases = properties.map { binding in
        let pattern = binding.pattern

        let change =
          if binding.typeAnnotation!.type.is(OptionalTypeSyntax.self) {
            "withChanges(\(pattern): { value as? \(binding.type.replacingOccurrences(of: "?", with: "")) })"
          } else {
            "withChanges(\(pattern): (value as! \(binding.type)))"
          }

        return "case \\Self.\(pattern): \(change)"
      }
      .joined(separator: "\n")

      // A switch keeps the generated code cheap to type-check: each case changes one property,
      // instead of one call with a key path comparison per property.
      let applyDeclaration: DeclSyntax = """
        public func apply(action: SetValue<Self, some Any>) -> Self {
          let value = action.value

          return switch action.path {
          \(raw: applicationCases)
          default:
            self
          }
        }
        """

      result.append(applyDeclaration)
    }

    return result
  }
}
