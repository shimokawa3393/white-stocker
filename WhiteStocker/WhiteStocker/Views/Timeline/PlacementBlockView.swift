//
//  PlacementBlockView.swift
//  WhiteStocker
//
//  配置済みブロックの描画。「タップ判定＝1Row」と「見た目＝時間軸比例配置」を分離する設計に基づき、
//  DayTimelineView側のZStack上に絶対配置（offset）される前提のView。
//
//  背景（background）とテキスト（content）を分離して公開している。DayTimelineView側で
//  「Row罫線 → 背景（タップ領域） → 現在時刻線 → テキスト」の順に重ねることで、
//  現在時刻線がテキストの可読性を妨げず、かつブロックの背景に完全に隠れて消えることもない
//  中間レイヤーに来るようにするため。
//

import SwiftUI

/// Viewプロトコルには準拠しない。background/contentという2つの部品を提供するだけの構造体。
/// DayTimelineView側で、それぞれを別レイヤーとしてZStackに組み込んで使う。
struct PlacementBlockView {
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

    /// 隣接する配置同士（終了時刻＝次の開始時刻）が背景ごとぴったり接して見えるのを避けるため、
    /// 上下均等に切り詰めて隙間を作る。上端がblockGap/2だけ正確な開始時刻より下にずれるが、
    /// 視覚的な対称性を優先する（ズレはごくわずかで実用上問題にならない）。
    private static let blockGap: CGFloat = 3

    /// Button側でoffset適用するために公開する（PlacementBlockView内部でoffsetすると、
    /// Buttonのタップ領域がoffset適用前のフレーム位置で計算されてしまいタップできなくなるため）
    var yOffset: CGFloat {
        CGFloat(minutesFromStartOfDay) * (TimelineRowView.rowHeight / 60) + Self.blockGap / 2
    }

    var xOffset: CGFloat {
        contentLeadingInset + laneWidth * CGFloat(layout.laneIndex)
    }

    /// 時間軸に厳密に比例させる。下限クランプを設けると短い配置が実際の時間帯をはみ出して
    /// 描画されてしまうため、最小高さの底上げはしない（窮屈さの緩和はpadding/フォント側で行う）。
    private var blockHeight: CGFloat {
        max(CGFloat(placement.durationMin) * (TimelineRowView.rowHeight / 60) - Self.blockGap, 4)
    }

    private var laneWidth: CGFloat {
        guard layout.laneCount > 0 else { return contentWidth }
        return contentWidth / CGFloat(layout.laneCount)
    }

    private var blockSize: CGSize {
        CGSize(width: max(laneWidth - Spacing.xs, 0), height: blockHeight)
    }

    /// 角丸が固定値のままだと、高さの低いブロック（15分の配置など）では角丸だけで
    /// 高さのほとんどを占めてしまい、直線部分がほぼ残らず「潰れた」形に見える。
    /// 高さの1/3を上限にすることでこれを防ぐ。
    private var cornerRadius: CGFloat {
        min(CornerRadius.small, blockSize.height / 3)
    }

    /// 背景・枠線のみ。DayTimelineView側でButtonのlabelとして使い、タップ領域を兼ねる。
    var background: some View {
        // ライトではグレー、ダークでは白方向に意味的に反転するColor.primaryベースの塗り。
        // タスク一覧・タスク選択より一段濃く、主役としての存在感を出す。
        CardBackground(
            cornerRadius: cornerRadius,
            fill: AppColor.elevatedFillGradient
        )
        .frame(width: blockSize.width, height: blockSize.height)
        .contentShape(Rectangle())
    }

    /// テキストのみ。背景より手前・現在時刻線よりさらに手前に重ねて表示する。タップは受け付けない。
    var content: some View {
        HStack(spacing: Spacing.xs) {
            Text(timeRangeText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.secondaryText)
                .lineLimit(1)
                .padding(.trailing, Spacing.xs)
            Text(placement.task.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.trailing, Spacing.xs)
            if let memo = placement.task.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption2)
                    .foregroundStyle(AppColor.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4) // rowHeightを90ptまで増やしたため、以前より余裕を持たせられる
        .frame(width: blockSize.width, height: blockSize.height, alignment: .leading)
        .clipped()
        .allowsHitTesting(false)
    }

    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: placement.startTime))〜\(formatter.string(from: placement.endTime))"
    }
}
