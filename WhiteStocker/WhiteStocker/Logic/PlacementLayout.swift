//
//  PlacementLayout.swift
//  WhiteStocker
//
//  同一Row内に複数Placementが存在する場合の横並びレーン割当ロジック。
//  Viewから独立した純粋関数として実装する（SlotFinderと同じ方針）。
//

import Foundation

struct PlacementLayoutItem {
    let placement: Placement
    /// 重なりクラスタ内でのレーン番号（0始まり）
    let laneIndex: Int
    /// そのクラスタの総レーン数（横幅の等分割数）
    let laneCount: Int
}

enum PlacementLayout {
    /// 指定Placement群を、時間的に重なるものだけをグループ化してレーン割当する。
    /// 重ならないPlacement同士は互いにレーン数へ影響しない（クラスタが分かれる）。
    static func layout(for placements: [Placement]) -> [PlacementLayoutItem] {
        let sorted = placements.sorted { $0.startTime < $1.startTime }

        var result: [PlacementLayoutItem] = []
        var cluster: [Placement] = []
        var clusterMaxEnd: Date?

        func flushCluster() {
            guard !cluster.isEmpty else { return }
            result.append(contentsOf: assignLanes(cluster))
            cluster = []
            clusterMaxEnd = nil
        }

        for placement in sorted {
            if let maxEnd = clusterMaxEnd, placement.startTime >= maxEnd {
                flushCluster()
            }
            cluster.append(placement)
            clusterMaxEnd = max(clusterMaxEnd ?? placement.endTime, placement.endTime)
        }
        flushCluster()

        return result
    }

    /// 1クラスタ内のPlacementに、空いている最小のレーン番号を割り当てる
    private static func assignLanes(_ cluster: [Placement]) -> [PlacementLayoutItem] {
        var laneEndTimes: [Date] = []
        var assignments: [(placement: Placement, laneIndex: Int)] = []

        for placement in cluster {
            if let laneIndex = laneEndTimes.firstIndex(where: { $0 <= placement.startTime }) {
                laneEndTimes[laneIndex] = placement.endTime
                assignments.append((placement, laneIndex))
            } else {
                laneEndTimes.append(placement.endTime)
                assignments.append((placement, laneEndTimes.count - 1))
            }
        }

        let laneCount = laneEndTimes.count
        return assignments.map {
            PlacementLayoutItem(placement: $0.placement, laneIndex: $0.laneIndex, laneCount: laneCount)
        }
    }
}
