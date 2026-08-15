//
//  AppColorSchemePreference.swift
//  WhiteStocker
//
//  デバイスのシステム設定とは独立に、アプリ内でライト/ダークを切り替えるための設定。
//  UserDefaults（@AppStorage）で永続化する。
//

import SwiftUI

enum AppColorSchemePreference: String, CaseIterable {
    case system
    case light
    case dark

    /// nilを返すとpreferredColorScheme(nil)相当になり、システム設定に従う
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "システムに従う"
        case .light: return "ライト"
        case .dark: return "ダーク"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}
