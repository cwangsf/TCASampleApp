//
//  TodoRepositoryClient.swift
//  TCASampleApp
//
//  Created by Claude Code on 12/12/25.
//

import Dependencies
import Foundation
import SwiftData

struct TodoRepositoryClient {
    var fetchTodos: @MainActor () async throws -> [TodoFeature.State.Todo]
    var fetchCategories: @MainActor () async throws -> [TodoFeature.State.Category]
    var saveTodo: @MainActor (TodoFeature.State.Todo) async throws -> TodoFeature.State.Todo
    var updateTodo: @MainActor (TodoFeature.State.Todo) async throws -> TodoFeature.State.Todo
    var deleteTodo: @MainActor (UUID) async throws -> Void
    var saveCategory: @MainActor (TodoFeature.State.Category) async throws -> TodoFeature.State.Category
    var deleteCategory: @MainActor (UUID) async throws -> Void
}

extension TodoRepositoryClient: DependencyKey {
    @MainActor
    static func live(modelContext: ModelContext) -> TodoRepositoryClient {
        return TodoRepositoryClient(
            fetchTodos: {
                let descriptor = FetchDescriptor<TodoItemModel>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                let models = try modelContext.fetch(descriptor)
                return models.map { $0.toTodoState() }
            },
            fetchCategories: {
                let descriptor = FetchDescriptor<CategoryModel>(
                    sortBy: [SortDescriptor(\.name)]
                )
                let models = try modelContext.fetch(descriptor)
                return models.map { $0.toCategoryState() }
            },
            saveTodo: { todo in
                let model = TodoItemModel(
                    id: todo.id,
                    title: todo.title,
                    isCompleted: todo.isCompleted,
                    createdAt: todo.createdAt,
                    dueDate: todo.dueDate,
                    reminderDate: todo.reminderDate,
                    notes: todo.notes
                )

                // Associate with category if specified
                if let categoryId = todo.categoryId {
                    let catId = categoryId
                    let categoryDescriptor = FetchDescriptor<CategoryModel>(
                        predicate: #Predicate { $0.id == catId }
                    )
                    if let category = try modelContext.fetch(categoryDescriptor).first {
                        model.category = category
                    }
                }

                modelContext.insert(model)
                try modelContext.save()
                return model.toTodoState()
            },
            updateTodo: { todo in
                let todoId = todo.id
                let descriptor = FetchDescriptor<TodoItemModel>(
                    predicate: #Predicate { $0.id == todoId }
                )
                guard let model = try modelContext.fetch(descriptor).first else {
                    throw TodoRepositoryError.todoNotFound
                }

                model.title = todo.title
                model.isCompleted = todo.isCompleted
                model.dueDate = todo.dueDate
                model.reminderDate = todo.reminderDate
                model.notes = todo.notes

                // Update category relationship
                if let categoryId = todo.categoryId {
                    let catId = categoryId
                    let categoryDescriptor = FetchDescriptor<CategoryModel>(
                        predicate: #Predicate { $0.id == catId }
                    )
                    model.category = try modelContext.fetch(categoryDescriptor).first
                } else {
                    model.category = nil
                }

                try modelContext.save()
                return model.toTodoState()
            },
            deleteTodo: { id in
                let descriptor = FetchDescriptor<TodoItemModel>(
                    predicate: #Predicate { $0.id == id }
                )
                guard let model = try modelContext.fetch(descriptor).first else {
                    throw TodoRepositoryError.todoNotFound
                }
                modelContext.delete(model)
                try modelContext.save()
            },
            saveCategory: { category in
                let model = CategoryModel(
                    id: category.id,
                    name: category.name,
                    colorHex: category.colorHex,
                    iconName: category.iconName
                )
                modelContext.insert(model)
                try modelContext.save()
                return model.toCategoryState()
            },
            deleteCategory: { id in
                let descriptor = FetchDescriptor<CategoryModel>(
                    predicate: #Predicate { $0.id == id }
                )
                guard let model = try modelContext.fetch(descriptor).first else {
                    throw TodoRepositoryError.categoryNotFound
                }
                modelContext.delete(model)
                try modelContext.save()
            }
        )
    }

    static var liveValue: TodoRepositoryClient {
        fatalError("TodoRepositoryClient must be provided with modelContext at app launch")
    }

    static let testValue = TodoRepositoryClient(
        fetchTodos: unimplemented("fetchTodos"),
        fetchCategories: unimplemented("fetchCategories"),
        saveTodo: unimplemented("saveTodo"),
        updateTodo: unimplemented("updateTodo"),
        deleteTodo: unimplemented("deleteTodo"),
        saveCategory: unimplemented("saveCategory"),
        deleteCategory: unimplemented("deleteCategory")
    )
}

extension DependencyValues {
    var todoRepository: TodoRepositoryClient {
        get { self[TodoRepositoryClient.self] }
        set { self[TodoRepositoryClient.self] = newValue }
    }
}

enum TodoRepositoryError: Error, Equatable {
    case todoNotFound
    case categoryNotFound
}
