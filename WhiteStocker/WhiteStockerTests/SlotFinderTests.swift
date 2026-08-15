//
//  SlotFinderTests.swift
//  WhiteStockerTests
//
//  SlotFinder（空きスロット計算ロジック）の境界値テスト。
//

import Testing
import Foundation
@testable import WhiteStocker

struct SlotFinderTests {
    private let calendar = Calendar.current

    private func time(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: calendar.startOfDay(for: Date())
        )!
    }

    private func makePlacement(start: Date, durationMin: Int) -> Placement {
        let task = TaskItem(name: "テスト", durationMin: durationMin)
        return Placement(task: task, date: start, startTime: start, durationMin: durationMin)
    }

    // MARK: - availableSlots

    @Test func 既存配置が無ければRow全体が空きスロットになる() {
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: []
        )
        #expect(slots.count == 1)
        #expect(slots[0].start == time(10))
        #expect(slots[0].end == time(11))
    }

    @Test func Row内の配置の前後に空きスロットができる() {
        // 10:20-10:40 を占有 → 前後に空き。後半は15分刻みスナップで10:45開始になる
        let placement = makePlacement(start: time(10, 20), durationMin: 20)
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [placement]
        )
        #expect(slots.count == 2)
        #expect(slots[0].start == time(10, 0))
        #expect(slots[0].end == time(10, 20))
        #expect(slots[1].start == time(10, 45))
        #expect(slots[1].end == time(11, 0))
    }

    @Test func Rowを完全に占有する配置があれば空きスロットは無い() {
        let placement = makePlacement(start: time(9, 30), durationMin: 120) // 9:30-11:30
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [placement]
        )
        #expect(slots.isEmpty)
    }

    @Test func 前のRowから続く配置はRow開始から占有として扱われる() {
        let placement = makePlacement(start: time(9, 0), durationMin: 90) // 9:00-10:30
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [placement]
        )
        #expect(slots.count == 1)
        #expect(slots[0].start == time(10, 30))
        #expect(slots[0].end == time(11, 0))
    }

    @Test func 端数分しか残らない空き区間は候補から除外される() {
        let placement = makePlacement(start: time(10, 50), durationMin: 10) // 10:50-11:00
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [placement]
        )
        // 10:00-10:50（50分）のみが候補。10:50以降は占有かつ端数分も無い
        #expect(slots.count == 1)
        #expect(slots[0].start == time(10, 0))
        #expect(slots[0].end == time(10, 50))
    }

    @Test func ちょうど15分の空き区間は候補に含まれる() {
        let placement = makePlacement(start: time(10, 0), durationMin: 45) // 10:00-10:45
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [placement]
        )
        #expect(slots.count == 1)
        #expect(slots[0].start == time(10, 45))
        #expect(slots[0].end == time(11, 0))
    }

    @Test func 隣接する配置の端点が一致する場合は隙間なしとして扱われる() {
        let p1 = makePlacement(start: time(10, 0), durationMin: 20)  // 10:00-10:20
        let p2 = makePlacement(start: time(10, 20), durationMin: 20) // 10:20-10:40（p1と端点一致）
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [p1, p2]
        )
        #expect(slots.count == 1)
        #expect(slots[0].start == time(10, 45)) // 10:40を15分刻みに切り上げ
        #expect(slots[0].end == time(11, 0))
    }

    @Test func 同一Row内に複数の空き区間が離れて存在できる() {
        let p1 = makePlacement(start: time(10, 15), durationMin: 15) // 10:15-10:30
        let p2 = makePlacement(start: time(10, 45), durationMin: 15) // 10:45-11:00
        let slots = SlotFinder.availableSlots(
            rowStart: time(10), rowEnd: time(11), existingPlacements: [p1, p2]
        )
        #expect(slots.count == 2)
        #expect(slots[0].start == time(10, 0))
        #expect(slots[0].end == time(10, 15))
        #expect(slots[1].start == time(10, 30))
        #expect(slots[1].end == time(10, 45))
    }

    // MARK: - maxAvailableDuration

    @Test func 次の予定が無ければ日の終わりまでが最大所要時間になる() {
        let minutes = SlotFinder.maxAvailableDuration(from: time(23, 0), existingPlacements: [])
        #expect(minutes == 60)
    }

    @Test func 次の予定があればそこまでが最大所要時間になる() {
        let next = makePlacement(start: time(10, 40), durationMin: 30)
        let minutes = SlotFinder.maxAvailableDuration(from: time(10, 0), existingPlacements: [next])
        #expect(minutes == 40)
    }

    @Test func 開始時刻より前の配置は最大所要時間の計算に影響しない() {
        let past = makePlacement(start: time(9, 0), durationMin: 30) // 9:00-9:30、startより前
        let minutes = SlotFinder.maxAvailableDuration(from: time(10, 0), existingPlacements: [past])
        #expect(minutes == 14 * 60) // 10:00〜24:00
    }
}
