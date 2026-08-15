//
//  PlacementBlockView.swift
//  WhiteStocker
//
//  配置済みブロックの描画。「タップ判定＝1Row」と「見た目＝時間軸比例配置」を分離する設計に基づき、
//  DayTimelineView側のZStack上に絶対配置（offset）される前提のView。
//

import SwiftUI

struct PlacementBlockView: View {
    let layout: PlacementLayoutItem
    /// タイムライン左側の時刻ラベル分のオフセット（TimelineRowViewのレイアウトに合わせる）
    let contentLeadingInset: CGFloat
    /// Row本体（時刻ラベルを除いた）の利用可能な横幅
    let contentWidth: CGFloat

    private var placement: Placement { layout.placement }

    private var minutesFromStartOfDay: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: placement.startTime)
        return calendar.dateComponents([.minute], from: startOfDay, to: placement.startTime).minute ?? 0
    }

    private var yOffset: CGFloat {
        CGFloat(minutesFromStartOfDay) * (TimelineRowView.rowHeight / 60)
    }

    /// 時間軸に厳密に比例させる。下限クランプを設けると短い配置が実際の時間帯をはみ出して
    /// 描画されてしまうため、最小高さの底上げはしない（窮屈さの緩和はpadding/フォント側で行う）。
    private var blockHeight: CGFloat {
        CGFloat(placement.durationMin) * (TimelineRowView.rowHeight / 60)
    }

    private var laneWidth: CGFloat {
        guard layout.laneCount > 0 else { return contentWidth }
        return contentWidth / CGFloat(layout.laneCount)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(placement.task.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(timeRangeText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .frame(width: max(laneWidth - 4, 0), height: blockHeight, alignment: .leading)
        .background(Color.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .clipped()
        .offset(
            x: contentLeadingInset + laneWidth * CGFloat(layout.laneIndex),
            y: yOffset
        )
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: placement.startTime))〜\(formatter.string(from: placement.endTime))"
    }
}
