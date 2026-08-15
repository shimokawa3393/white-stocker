//
//  WarningLabel.swift
//  WhiteStocker
//
//  フォーム内で使う警告メッセージの共通表示。アイコン付きで視認性を高める。
//  PlacementEditSheet / SlotPickerSheet の重複警告・所要時間超過警告で使う。
//

import SwiftUI

struct WarningLabel: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.red)
    }
}
