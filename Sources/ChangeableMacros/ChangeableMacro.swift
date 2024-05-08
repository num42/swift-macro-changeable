import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ChangeableFunctionMacro: MemberMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDeclaration = declaration.as(StructDeclSyntax.self) else {
            return []
        }

        let bindings = structDeclaration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .flatMap(\.bindings)

        // ignore computed properties
        let properties = bindings
            .filter { $0.accessorBlock == nil }

        let parameters = properties
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

private extension PatternBindingListSyntax.Element {
    var type: String {
        // remove any inlined comments after the type
        typeAnnotation!.type.description
            .components(separatedBy: "//")
            .first!
            .trimmingCharacters(in: .whitespaces)
    }
}

@main
struct ChangeablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ChangeableFunctionMacro.self,
    ]
}
