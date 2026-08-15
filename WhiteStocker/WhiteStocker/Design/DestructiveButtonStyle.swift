//
//  DestructiveButtonStyle.swift
//  WhiteStocker
//
//  Form内のインラインアクションボタン（配置の削除など）に使う共通スタイル。
//  CardBackgroundと統一感のある質感（塗り＋グラデーション枠線＋2層シャドウ）を持たせることで、
//  Form標準の飾り気のないボタンから、他の要素と一貫した見た目にする。
//

import SwiftUI

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                CardBackground(cornerRadius: CornerRadius.medium, fill: AppColor.subtleFill)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
