//
//  AppFeature.swift
//  TCASampleApp
//
//  Created by Cynthia Wang on 12/12/25.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    struct State: Equatable { }
    enum Action { }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}
