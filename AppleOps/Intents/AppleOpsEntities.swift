import AppIntents
import SwiftUI

struct BuildRunEntity: AppEntity {
    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "构建"
    nonisolated static let defaultQuery = BuildRunEntityQuery()

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

struct ToolsScreenEntity: AppEntity {
    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Tools Screen"
    nonisolated static let defaultQuery = ToolsScreenQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct ToolsScreenQuery: EntityQuery {
    func entities(for identifiers: [ToolsScreenEntity.ID]) async throws -> [ToolsScreenEntity] {
        identifiers.map { ToolsScreenEntity(id: $0, title: $0) }
    }

    func suggestedEntities() async throws -> [ToolsScreenEntity] {
        [
            ToolsScreenEntity(id: "builds", title: "Builds"),
            ToolsScreenEntity(id: "devices", title: "Devices"),
            ToolsScreenEntity(id: "machines", title: "Machines"),
        ]
    }
}

struct MachineEntity: AppEntity {
    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Machine"
    nonisolated static let defaultQuery = MachineQuery()

    var id: String
    var title: String
    var status: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct MachineQuery: EntityQuery {
    func entities(for identifiers: [MachineEntity.ID]) async throws -> [MachineEntity] {
        identifiers.map { MachineEntity(id: $0, title: $0, status: "") }
    }

    func suggestedEntities() async throws -> [MachineEntity] {
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

    @ViewBuilder
    func appleOpsMachineAnnotation(_ id: String) -> some View {
        if #available(iOS 27.0, *) {
            self.appEntityIdentifier(
                EntityIdentifier(for: MachineEntity.self, identifier: id)
            )
        } else {
            self
        }
    }
}
