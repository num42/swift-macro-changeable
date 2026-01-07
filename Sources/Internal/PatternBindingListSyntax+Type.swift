import SwiftSyntax

extension PatternBindingListSyntax.Element {
  var type: String {
    // remove any inlined comments after the type
    typeAnnotation!.type.description
      .components(separatedBy: "//")
      .first!
      .trimmingCharacters(in: .whitespaces)
  }
}
