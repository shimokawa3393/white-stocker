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
    /// 時刻ラベル幅 + spacing。PlacementBlockViewのcontentLeadingInsetと一致させる。
    static let labelWidth: CGFloat = 44
    static let labelSpacing: CGFloat = Spacing.sm

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 正時の罫線はRow上端（=正確にその時刻）にぴったり合わせる。
            // PlacementBlockViewのY座標計算がこの位置を基準にしているため、
            // ここにpaddingを掛けるとブロックの表示位置とズレる。
            Rectangle()
                .fill(AppColor.divider)
                .frame(height: 1)
                .padding(.leading, Self.labelWidth + Self.labelSpacing)

            // 30分位置の補助線（正時より控えめに）
            Rectangle()
                .fill(AppColor.divider.opacity(0.5))
                .frame(height: 1)
                .padding(.leading, Self.labelWidth + Self.labelSpacing)
                .offset(y: Self.rowHeight / 2)

            Text(String(format: "%02d:00", hour))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: Self.labelWidth, alignment: .trailing)
                .offset(y: -6) // 罫線の位置を基準に、ラベルの見た目だけ少し持ち上げる
        }
        .frame(height: Self.rowHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityIdentifier("timeline-row-\(hour)")
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(0..<3, id: \.self) { hour in
            TimelineRowView(hour: hour)
        }
    }
}
