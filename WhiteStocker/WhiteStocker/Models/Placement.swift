//
//  Placement.swift
//  WhiteStocker
//
//  「タスクの配置」を表すモデル。Taskをその日のタイムラインに配置した実体。
//

import Foundation
import SwiftData

@Model
final class Placement {
    var id: UUID
    var task: TaskItem
    /// 配置日。必ず Calendar.current.startOfDay(for:) で00:00に正規化してから保存・クエリすること
    var date: Date
    var startTime: Date
    /// Task.durationMin を初期値としてコピーするが、以後は独立して編集可能
    var durationMin: Int
    var createdAt: Date

    init(
        task: TaskItem,
        date: Date,
        startTime: Date,
        durationMin: Int,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.task = task
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.durationMin = durationMin
        self.createdAt = createdAt
    }

    /// 配置の終了時刻
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: durationMin, to: startTime) ?? startTime
    }
}
