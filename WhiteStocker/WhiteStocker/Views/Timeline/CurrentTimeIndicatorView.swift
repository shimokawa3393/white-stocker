//
//  CurrentTimeIndicatorView.swift
//  WhiteStocker
//
//  現在時刻を示すインジケーター。時刻ラベル脇の小さなマーカーから、
//  Row全体を貫く水平線を引く（標準カレンダーアプリ等に倣ったパターン）。
//  線を右まで伸ばすことで、現在時刻と配置ブロックの前後関係が一目でわかるようにする。
//

import SwiftUI

struct CurrentTimeIndicatorView: View {
    /// タイムライン左側の時刻ラベル分のオフセット（TimelineRowViewのレイアウトに合わせる）
    let contentLeadingInset: CGFloat
    let currentTime: Date

    private var minutesFromStartOfDay: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentTime)
        return calendar.dateComponents([.minute], from: startOfDay, to: currentTime).minute ?? 0
    }

    private var yOffset: CGFloat {
        CGFloat(minutesFromStartOfDay) * (TimelineRowView.rowHeight / 60)
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color.accentColor)
                .frame(width: contentLeadingInset, alignment: .trailing)

            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 1.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(y: yOffset - 4)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack(alignment: .topLeading) {
        VStack(spacing: 0) {
            ForEach(9..<12, id: \.self) { hour in
                TimelineRowView(hour: hour)
            }
        }
        CurrentTimeIndicatorView(contentLeadingInset: 52, currentTime: .now)
    }
}
