//
//  TimelineRowView.swift
//  WhiteStocker
//
//  1時間刻みのRow。「1タップ範囲＝1Row」の単位。
//  Placementブロックの見た目（時間軸比例配置）は別レイヤー（PlacementBlockView, Step6）が担当する。
//

import SwiftUI

struct TimelineRowView: View {
    let hour: Int

    /// 1時間あたりの高さ(pt)。PlacementBlockViewの絶対配置計算の基準値として共有する。
    static let rowHeight: CGFloat = 60

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(String(format: "%02d:00", hour))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.top, 6)
        .frame(height: Self.rowHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // TODO: Step6でタップ時に空きスロット提示（SlotPickerSheet）へ繋ぐ
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(0..<3, id: \.self) { hour in
            TimelineRowView(hour: hour)
        }
    }
}
