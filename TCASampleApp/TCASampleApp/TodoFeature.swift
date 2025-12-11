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
        
        struct Todo: Equatable, Identifiable {
            let id: UUID
            var title: String
            var isCompleted: Bool
            
            init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
                self.id = id
                self.title = title
                self.isCompleted = isCompleted
            }
        }
    }
    
    // MARK: - Action
    // Actions represent all the things that can happen in your feature
    enum Action {
        case newTodoTextChanged(String)
        case addTodoButtonTapped
        case todoToggled(id: UUID)
        case deleteTodos(IndexSet)
    }
    
    // MARK: - Reducer
    // The reducer is the heart of TCA - pure logic that transforms state
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .newTodoTextChanged(text):
                state.newTodoText = text
                return .none
                
            case .addTodoButtonTapped:
                guard !state.newTodoText.isEmpty else { return .none }
                
                let newTodo = State.Todo(title: state.newTodoText)
                state.todos.append(newTodo)
                state.newTodoText = ""
                return .none
                
            case let .todoToggled(id):
                state.todos[id: id]?.isCompleted.toggle()
                return .none
                
            case let .deleteTodos(indexSet):
                state.todos.remove(atOffsets: indexSet)
                return .none
            }
        }
    }
}
