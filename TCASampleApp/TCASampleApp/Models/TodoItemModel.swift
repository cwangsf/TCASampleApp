//
//  TodoItemModel.swift
//  TCASampleApp
//
//  Created by Claude Code on 12/12/25.
//

import Foundation
import SwiftData

@Model
final class TodoItemModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var reminderDate: Date?
    var notes: String?

    // Relationship to category
    @Relationship(deleteRule: .nullify, inverse: \CategoryModel.todos)
    var category: CategoryModel?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.notes = notes
    }
}
