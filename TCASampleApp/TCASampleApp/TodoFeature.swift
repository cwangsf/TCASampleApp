//
//  TodoFeature.swift
//  TCASampleApp
//
//  Created by Cynthia Wang on 12/11/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - State
// State represents all the data your feature needs
@Reducer
struct TodoFeature {
    struct State: Equatable {
        var todos: IdentifiedArrayOf<Todo> = []
        var newTodoText: String = ""
        var categories: IdentifiedArrayOf<Category> = []
        var selectedCategoryId: UUID? = nil
        var isLoading: Bool = false
        var editingTodo: Todo? = nil
        var filter: TodoFilter = .all
        var sortOrder: SortOrder = .createdDate

        struct Todo: Equatable, Identifiable {
            let id: UUID
            var title: String
            var isCompleted: Bool
            var createdAt: Date
            var dueDate: Date?
            var reminderDate: Date?
            var notes: String?
            var categoryId: UUID?

            init(
                id: UUID = UUID(),
                title: String,
                isCompleted: Bool = false,
                createdAt: Date = Date(),
                dueDate: Date? = nil,
                reminderDate: Date? = nil,
                notes: String? = nil,
                categoryId: UUID? = nil
            ) {
                self.id = id
                self.title = title
                self.isCompleted = isCompleted
                self.createdAt = createdAt
                self.dueDate = dueDate
                self.reminderDate = reminderDate
                self.notes = notes
                self.categoryId = categoryId
            }
        }

        struct Category: Equatable, Identifiable {
            let id: UUID
            var name: String
            var colorHex: String
            var iconName: String?

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
            }
        }

        enum TodoFilter: Equatable {
            case all
            case active
            case completed
            case category(UUID)
            case dueToday
            case dueSoon
        }

        enum SortOrder: Equatable {
            case createdDate
            case dueDate
            case title
        }
    }
    
    // MARK: - Action
    // Actions represent all the things that can happen in your feature
    enum Action: Equatable {
        // Existing actions
        case newTodoTextChanged(String)
        case addTodoButtonTapped
        case todoToggled(id: UUID)
        case deleteTodos(IndexSet)

        // Lifecycle actions
        case onAppear
        case onDisappear

        // Persistence actions
        case loadTodosResponse(Result<[State.Todo], Error>)
        case loadCategoriesResponse(Result<[State.Category], Error>)
        case saveTodoResponse(Result<State.Todo, Error>)
        case deleteTodoResponse(Result<UUID, Error>)

        // Category management
        case createCategory(name: String, colorHex: String, iconName: String?)
        case categoryCreated(Result<State.Category, Error>)
        case deleteCategory(UUID)
        case selectCategory(UUID?)

        // Todo editing
        case editTodo(State.Todo)
        case updateTodo(id: UUID, title: String?, dueDate: Date?, reminderDate: Date?, notes: String?, categoryId: UUID?)
        case todoUpdated(Result<State.Todo, Error>)
        case cancelEditing

        // Filtering and sorting
        case filterChanged(State.TodoFilter)
        case sortOrderChanged(State.SortOrder)

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.newTodoTextChanged(let a), .newTodoTextChanged(let b)):
                return a == b
            case (.addTodoButtonTapped, .addTodoButtonTapped):
                return true
            case (.todoToggled(let a), .todoToggled(let b)):
                return a == b
            case (.deleteTodos(let a), .deleteTodos(let b)):
                return a == b
            case (.onAppear, .onAppear):
                return true
            case (.onDisappear, .onDisappear):
                return true
            case (.selectCategory(let a), .selectCategory(let b)):
                return a == b
            case (.editTodo(let a), .editTodo(let b)):
                return a == b
            case (.cancelEditing, .cancelEditing):
                return true
            case (.filterChanged(let a), .filterChanged(let b)):
                return a == b
            case (.sortOrderChanged(let a), .sortOrderChanged(let b)):
                return a == b
            default:
                return false
            }
        }
    }
    
    // MARK: - Reducer
    // The reducer is the heart of TCA - pure logic that transforms state
    @Dependency(\.todoRepository) var todoRepository

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: - Lifecycle
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.loadTodosResponse(Result {
                        try await todoRepository.fetchTodos()
                    }))
                    await send(.loadCategoriesResponse(Result {
                        try await todoRepository.fetchCategories()
                    }))
                }

            case .onDisappear:
                return .none

            // MARK: - Loading responses
            case let .loadTodosResponse(.success(todos)):
                state.isLoading = false
                state.todos = IdentifiedArray(uniqueElements: todos)
                return .none

            case let .loadTodosResponse(.failure(error)):
                state.isLoading = false
                print("Error loading todos: \(error)")
                return .none

            case let .loadCategoriesResponse(.success(categories)):
                state.categories = IdentifiedArray(uniqueElements: categories)
                return .none

            case let .loadCategoriesResponse(.failure(error)):
                print("Error loading categories: \(error)")
                return .none

            // MARK: - Todo CRUD
            case let .newTodoTextChanged(text):
                state.newTodoText = text
                return .none

            case .addTodoButtonTapped:
                guard !state.newTodoText.isEmpty else { return .none }

                let newTodo = State.Todo(
                    title: state.newTodoText,
                    categoryId: state.selectedCategoryId
                )
                state.newTodoText = ""

                return .run { send in
                    await send(.saveTodoResponse(Result {
                        try await todoRepository.saveTodo(newTodo)
                    }))
                }

            case let .saveTodoResponse(.success(todo)):
                state.todos.insert(todo, at: 0)
                return .none

            case let .saveTodoResponse(.failure(error)):
                print("Error saving todo: \(error)")
                return .none

            case let .todoToggled(id):
                guard var todo = state.todos[id: id] else { return .none }
                todo.isCompleted.toggle()
                state.todos[id: id] = todo

                let updatedTodo = todo
                return .run { send in
                    await send(.todoUpdated(Result {
                        try await todoRepository.updateTodo(updatedTodo)
                    }))
                }

            case let .deleteTodos(indexSet):
                let idsToDelete = indexSet.map { state.todos[$0].id }
                state.todos.remove(atOffsets: indexSet)

                return .run { send in
                    for id in idsToDelete {
                        await send(.deleteTodoResponse(Result {
                            try await todoRepository.deleteTodo(id)
                            return id
                        }))
                    }
                }

            case .deleteTodoResponse(.success):
                return .none

            case let .deleteTodoResponse(.failure(error)):
                print("Error deleting todo: \(error)")
                return .none

            // MARK: - Todo editing
            case let .editTodo(todo):
                state.editingTodo = todo
                return .none

            case .cancelEditing:
                state.editingTodo = nil
                return .none

            case let .updateTodo(id, title, dueDate, reminderDate, notes, categoryId):
                guard var todo = state.todos[id: id] else { return .none }

                if let title = title { todo.title = title }
                if let dueDate = dueDate { todo.dueDate = dueDate }
                if let reminderDate = reminderDate { todo.reminderDate = reminderDate }
                if let notes = notes { todo.notes = notes }
                if let categoryId = categoryId { todo.categoryId = categoryId }

                state.todos[id: id] = todo
                state.editingTodo = nil

                let updatedTodo = todo
                return .run { send in
                    await send(.todoUpdated(Result {
                        try await todoRepository.updateTodo(updatedTodo)
                    }))
                }

            case let .todoUpdated(.success(todo)):
                state.todos[id: todo.id] = todo
                return .none

            case let .todoUpdated(.failure(error)):
                print("Error updating todo: \(error)")
                return .none

            // MARK: - Categories
            case let .createCategory(name, colorHex, iconName):
                let category = State.Category(name: name, colorHex: colorHex, iconName: iconName)
                return .run { send in
                    await send(.categoryCreated(Result {
                        try await todoRepository.saveCategory(category)
                    }))
                }

            case let .categoryCreated(.success(category)):
                state.categories.append(category)
                return .none

            case let .categoryCreated(.failure(error)):
                print("Error creating category: \(error)")
                return .none

            case let .deleteCategory(id):
                state.categories.remove(id: id)
                // Remove category reference from todos
                for todoId in state.todos.ids {
                    if state.todos[id: todoId]?.categoryId == id {
                        state.todos[id: todoId]?.categoryId = nil
                    }
                }
                return .run { _ in
                    try await todoRepository.deleteCategory(id)
                }

            case let .selectCategory(categoryId):
                state.selectedCategoryId = categoryId
                return .none

            // MARK: - Filtering/Sorting
            case let .filterChanged(filter):
                state.filter = filter
                return .none

            case let .sortOrderChanged(sortOrder):
                state.sortOrder = sortOrder
                return .none
            }
        }
    }
}
