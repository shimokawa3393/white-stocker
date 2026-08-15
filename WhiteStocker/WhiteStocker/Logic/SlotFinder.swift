//
//  SlotFinder.swift
//  WhiteStocker
//
//  空きスロット計算ロジック。Viewから独立した純粋関数として実装し、単体テスト可能にする。
//  タイムライン操作設計における「配置フロー」の心臓部。
//

import Foundation

enum SlotFinder {
    /// 指定Rowの時間帯内で、既存Placementと被らない空き区間を返す。
    /// 各区間の開始時刻はstepMinutes刻みにスナップ済み。stepMinutes未満の区間は候補から除外する。
    static func availableSlots(
        rowStart: Date,
        rowEnd: Date,
        existingPlacements: [Placement],
        stepMinutes: Int = 15,
        calendar: Calendar = .current
    ) -> [DateInterval] {
        guard rowStart < rowEnd else { return [] }

        // Rowの時間帯と重なるPlacementのみを対象にし、開始時刻でソートする
        let relevant = existingPlacements
            .filter { $0.startTime < rowEnd && $0.endTime > rowStart }
            .sorted { $0.startTime < $1.startTime }

        // その日の全Placementから、Rowの時間帯内の空き区間（生の区間、未スナップ）を洗い出す
        var rawFreeRanges: [(start: Date, end: Date)] = []
        var cursor = rowStart
        for placement in relevant {
            let occupiedStart = max(placement.startTime, rowStart)
            if occupiedStart > cursor {
                rawFreeRanges.append((cursor, occupiedStart))
            }
            cursor = max(cursor, min(placement.endTime, rowEnd))
        }
        if cursor < rowEnd {
            rawFreeRanges.append((cursor, rowEnd))
        }

        // 各区間の開始をstepMinutes刻みに切り上げ、stepMinutes未満しか残らない区間は除外
        return rawFreeRanges.compactMap { range in
            let snappedStart = snapUp(range.start, stepMinutes: stepMinutes, calendar: calendar)
            guard snappedStart < range.end else { return nil }
            let minutes = calendar.dateComponents([.minute], from: snappedStart, to: range.end).minute ?? 0
            guard minutes >= stepMinutes else { return nil }
            return DateInterval(start: snappedStart, end: range.end)
        }
    }

    /// 指定区間が既存Placement群のいずれかと重なるかどうか。配置の編集時の妥当性チェックに使う。
    static func hasConflict(start: Date, end: Date, existingPlacements: [Placement]) -> Bool {
        existingPlacements.contains { $0.startTime < end && $0.endTime > start }
    }

    /// 指定開始時刻から見て、次の既存Placementにぶつかるまで（またはその日の終わりまで）に
    /// 確保できる最大分数を返す。durationのクイック上書き時の妥当性チェックに使う。
    static func maxAvailableDuration(
        from start: Date,
        existingPlacements: [Placement],
        calendar: Calendar = .current
    ) -> Int {
        let dayEnd = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: start)
        ) ?? start

        let nextStart = existingPlacements
            .map(\.startTime)
            .filter { $0 > start }
            .min() ?? dayEnd

        let cappedEnd = min(nextStart, dayEnd)
        let minutes = calendar.dateComponents([.minute], from: start, to: cappedEnd).minute ?? 0
        return max(0, minutes)
    }

    /// 指定時刻を、その日の00:00を起点とするstepMinutes刻みの直近の時刻に切り上げる
    private static func snapUp(_ date: Date, stepMinutes: Int, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let totalMinutes = calendar.dateComponents([.minute], from: startOfDay, to: date).minute ?? 0
        let remainder = totalMinutes % stepMinutes
        guard remainder != 0 else { return date }
        let minutesToAdd = stepMinutes - remainder
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: date) ?? date
    }
}
