//
//  WhiteStockerApp.swift
//  WhiteStocker
//
//  Created by Shouhei Shimokawa on 2026/08/15.
//

import SwiftUI
import SwiftData

@main
struct WhiteStockerApp: App {
    var sharedModelContainer: ModelContainer = {
        // TODO: Step 2でTask / Placementモデルを実装したらここに追加する
        let schema = Schema([
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
