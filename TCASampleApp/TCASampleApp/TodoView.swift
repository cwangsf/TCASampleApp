//
//  TodoView.swift
//  TCASampleApp
//
//  Created by Cynthia Wang on 12/11/25.
//

import ComposableArchitecture
import SwiftUI

struct TodoView: View {
    // The store connects your view to the TCA runtime
    let store: StoreOf<TodoFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack(spacing: 0) {
                    // Input section
                    HStack {
                        TextField("New todo", text: viewStore.binding(
                            get: \.newTodoText,
                            send: TodoFeature.Action.newTodoTextChanged
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        Button("Add") {
                            viewStore.send(.addTodoButtonTapped)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewStore.newTodoText.isEmpty)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Todo list
                    if viewStore.todos.isEmpty {
                        ContentUnavailableView(
                            "No Todos",
                            systemImage: "checkmark.circle",
                            description: Text("Add your first todo above")
                        )
                    } else {
                        List {
                            ForEach(viewStore.todos) { todo in
                                TodoRowView(
                                    todo: todo,
                                    onToggle: { viewStore.send(.todoToggled(id: todo.id)) }
                                )
                            }
                            .onDelete { indexSet in
                                viewStore.send(.deleteTodos(indexSet))
                            }
                        }
                    }
                }
                .navigationTitle("TCA Todo List")
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onDisappear {
                viewStore.send(.onDisappear)
            }
        }
    }
}

struct TodoRowView: View {
    let todo: TodoFeature.State.Todo
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .gray)
                
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
