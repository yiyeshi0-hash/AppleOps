import AppIntents
import SwiftUI

struct BuildRunEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "构建"
    static var defaultQuery = BuildRunEntityQuery()

    var id: String
    var title: String
    var status: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct BuildRunEntityQuery: EntityQuery {
    func entities(for identifiers: [BuildRunEntity.ID]) async throws -> [BuildRunEntity] {
        identifiers.map { BuildRunEntity(id: $0, title: $0, status: "") }
    }

    func suggestedEntities() async throws -> [BuildRunEntity] {
        []
    }
}

extension View {
    @ViewBuilder
    func appleOpsAnnotation(_ id: String) -> some View {
        if #available(iOS 27.0, *) {
            self.appEntityIdentifier(
                EntityIdentifier(for: BuildRunEntity.self, identifier: id)
            )
        } else {
            self
        }
    }
}
