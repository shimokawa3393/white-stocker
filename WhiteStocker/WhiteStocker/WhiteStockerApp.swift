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
    @AppStorage("colorSchemePreference") private var colorSchemePreferenceRaw: String = AppColorSchemePreference.system.rawValue

    private var colorSchemePreference: AppColorSchemePreference {
        AppColorSchemePreference(rawValue: colorSchemePreferenceRaw) ?? .system
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            Placement.self,
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
                .preferredColorScheme(colorSchemePreference.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
