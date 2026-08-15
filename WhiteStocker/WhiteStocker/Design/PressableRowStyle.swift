//
//  PressableRowStyle.swift
//  WhiteStocker
//
//  タイムライン上のRow・配置ブロックをタップした際に、薄いハイライトで押下フィードバックを与える。
//  .onTapGestureは押下状態を検知できないため、Buttonをこのスタイルでラップして使う。
//

import SwiftUI

struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppColor.subtleFill : Color.clear)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
