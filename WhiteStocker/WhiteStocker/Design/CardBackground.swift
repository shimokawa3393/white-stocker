//
//  CardBackground.swift
//  WhiteStocker
//
//  アプリ全体で使う共通のカード風背景（塗り＋極細エッジ＋2層シャドウ）。
//  タスク一覧の行、タイムラインの配置ブロックなど、複数箇所でバラバラに実装すると
//  統一感を欠くため、ここに集約する。
//  fillは色でもグラデーションでも渡せるようジェネリックにしている。
//
//  枠線は最も細い線幅（0.5pt）＋AppColor.hairlineBorderGradient（上端が明るく下端がやや暗い）で、
//  はっきりした境界線ではなく「上から光が当たっている」ような繊細なエッジの質感を出す。
//

import SwiftUI

struct CardBackground<Fill: ShapeStyle>: View {
    var cornerRadius: CGFloat
    var fill: Fill

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppColor.hairlineBorderGradient, lineWidth: 0.5)
            )
            // 近い・鋭いコンタクトシャドウと、遠い・柔らかく広がるシャドウの2層で
            // 単純な1層シャドウより自然な浮遊感を出す。塗り・枠線の色は濃くしたくないが
            // 視認性は上げたいという要望のため、色とは別軸のシャドウ側で強める。
            .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.16), radius: 6, x: 0, y: 3)
    }
}
