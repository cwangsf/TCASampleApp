//
//  TCASampleApp.swift
//  TCASampleApp
//
//  Created by Cynthia Wang on 12/11/25.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
@MainActor
struct TCASampleApp: App {
    nonisolated var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TodoItemModel.self,
            CategoryModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                } withDependencies: {
                    $0.todoRepository = TodoRepositoryClient.live(modelContext: sharedModelContainer.mainContext)
                }
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
