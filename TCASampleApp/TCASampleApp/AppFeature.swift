//
//  AppFeature.swift
//  TCASampleApp
//
//  Created by Cynthia Wang on 12/12/25.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    struct State: Equatable {
        var todoFeature = TodoFeature.State()
    }

    enum Action {
        case todoFeature(TodoFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.todoFeature, action: \.todoFeature) {
            TodoFeature()
        }

        Reduce { state, action in
            switch action {
            case .todoFeature:
                return .none
            }
        }
    }
}
