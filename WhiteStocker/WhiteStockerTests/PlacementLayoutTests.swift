//
//  PlacementLayoutTests.swift
//  WhiteStockerTests
//
//  PlacementLayout（同一Row内の複数Placementのレーン割当）の境界値テスト。
//

import Testing
import Foundation
@testable import WhiteStocker

struct PlacementLayoutTests {
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

    @Test func 重ならない配置はそれぞれ単独レーンになる() {
        let p1 = makePlacement(start: time(9, 0), durationMin: 30)  // 9:00-9:30
        let p2 = makePlacement(start: time(10, 0), durationMin: 30) // 10:00-10:30（重複なし）
        let result = PlacementLayout.layout(for: [p1, p2])

        #expect(result.count == 2)
        for item in result {
            #expect(item.laneCount == 1)
            #expect(item.laneIndex == 0)
        }
    }

    @Test func 二つ重なる配置は2レーンに割り当てられる() {
        let p1 = makePlacement(start: time(10, 0), durationMin: 30) // 10:00-10:30
        let p2 = makePlacement(start: time(10, 15), durationMin: 30) // 10:15-10:45（p1と重なる）
        let result = PlacementLayout.layout(for: [p1, p2])

        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.laneCount == 2 })
        let lanes = Set(result.map(\.laneIndex))
        #expect(lanes == [0, 1])
    }

    @Test func 三つ同時に重なる配置は3レーンに割り当てられる() {
        let p1 = makePlacement(start: time(10, 0), durationMin: 60)  // 10:00-11:00
        let p2 = makePlacement(start: time(10, 10), durationMin: 60) // 10:10-11:10
        let p3 = makePlacement(start: time(10, 20), durationMin: 60) // 10:20-11:20
        let result = PlacementLayout.layout(for: [p1, p2, p3])

        #expect(result.count == 3)
        #expect(result.allSatisfy { $0.laneCount == 3 })
        let lanes = Set(result.map(\.laneIndex))
        #expect(lanes == [0, 1, 2])
    }

    @Test func 端点が一致するだけの配置は重ならない扱いでレーンを共有できる() {
        let p1 = makePlacement(start: time(10, 0), durationMin: 30)  // 10:00-10:30
        let p2 = makePlacement(start: time(10, 30), durationMin: 30) // 10:30-11:00（端点一致）
        let result = PlacementLayout.layout(for: [p1, p2])

        #expect(result.count == 2)
        // 端点一致は「重ならない」扱いなので、同一レーン(0)を共有できる
        #expect(result.allSatisfy { $0.laneCount == 1 && $0.laneIndex == 0 })
    }

    @Test func 離れた2つのクラスタは互いのレーン数に影響しない() {
        // 10:00台は2つ重なる、15:00台は重ならない単独 → 15:00台はlaneCount=1のまま
        let p1 = makePlacement(start: time(10, 0), durationMin: 30)
        let p2 = makePlacement(start: time(10, 10), durationMin: 30)
        let p3 = makePlacement(start: time(15, 0), durationMin: 30)
        let result = PlacementLayout.layout(for: [p1, p2, p3])

        let p3Layout = result.first { $0.placement.id == p3.id }
        #expect(p3Layout?.laneCount == 1)
        #expect(p3Layout?.laneIndex == 0)

        let clusterLaneCounts = result
            .filter { $0.placement.id != p3.id }
            .map(\.laneCount)
        #expect(clusterLaneCounts.allSatisfy { $0 == 2 })
    }
}
