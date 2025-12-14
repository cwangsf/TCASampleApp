//
//  TodoItemModel+Mapping.swift
//  TCASampleApp
//
//  Created by Claude Code on 12/12/25.
//

import Foundation

extension TodoItemModel {
    func toTodoState() -> TodoFeature.State.Todo {
        TodoFeature.State.Todo(
            id: id,
            title: title,
            isCompleted: isCompleted,
            createdAt: createdAt,
            dueDate: dueDate,
            reminderDate: reminderDate,
            notes: notes,
            categoryId: category?.id
        )
    }
}

extension CategoryModel {
    func toCategoryState() -> TodoFeature.State.Category {
        TodoFeature.State.Category(
            id: id,
            name: name,
            colorHex: colorHex,
            iconName: iconName
        )
    }
}
