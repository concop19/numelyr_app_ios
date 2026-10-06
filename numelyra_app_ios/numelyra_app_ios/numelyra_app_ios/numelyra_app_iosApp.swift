//
//  numelyra_app_iosApp.swift
//  numelyra_app_ios
//
//  Created by ManhLe on 10/6/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct numelyra_app_iosApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
