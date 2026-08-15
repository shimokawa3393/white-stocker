//
//  TaskItem.swift
//  WhiteStocker
//
//  「タスクの在庫」を表すモデル。配置（Placement）とは独立して存在し、
//  一度登録すれば繰り返しタイムラインへ配置できる。
//
//  設計書上の概念名は「Task」だが、Swift Concurrencyの標準型 Task<Success, Failure>
//  と名前が衝突するため、Swift上の型名は TaskItem とする。
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var name: String
    var memo: String?
    /// デフォルト所要時間（分）。Placement生成時の初期値として使われる
    var durationMin: Int
    var createdAt: Date
    /// 論理削除フラグ。物理削除はしない（過去のPlacementが参照切れを起こさないため）
    var deletedAt: Date?

    init(
        name: String,
        memo: String? = nil,
        durationMin: Int,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.memo = memo
        self.durationMin = durationMin
        self.createdAt = createdAt
        self.deletedAt = nil
    }

    var isDeleted: Bool {
        deletedAt != nil
    }
}
