//
//  CategoryModel.swift
//  TCASampleApp
//
//  Created by Claude Code on 12/12/25.
//

import Foundation
import SwiftData

@Model
final class CategoryModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var iconName: String?

    @Relationship(deleteRule: .cascade)
    var todos: [TodoItemModel]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.todos = []
    }
}
