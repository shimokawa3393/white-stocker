//
//  DesignTokens.swift
//  WhiteStocker
//
//  デザインの一貫性を保つための共通トークン（余白・角丸・色階調）。
//  各Viewでその場しのぎの数値をハードコードするのではなく、ここに集約して参照する。
//  モノトーン方針（設計書v0スコープ）を維持しつつ、階調に意味を持たせる。
//

import SwiftUI
import UIKit

/// 余白の基準値。4pt刻みのスケール。
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

/// 角丸の基準値。
enum CornerRadius {
    /// ブロック・チップなど、小さめの要素
    static let small: CGFloat = 7
    /// カード・シートのコンテナなど
    static let medium: CGFloat = 10
}

/// モノトーン方針の中での色階調。用途ごとに意味を持たせて命名する。
///
/// 塗り系のトークン（subtleFill・elevatedFill*）は必ず不透明にする。過去にColor.primary.opacity()
/// のような半透明の塗りを使い、背後の罫線が透けて見える問題が2度発生したため、UIColorの
/// 動的トレイトでライト/ダークそれぞれに不透明な色を明示的に定義している（Color.primaryの
/// 意味的な反転＝ライトで黒系・ダークで白系、という関係は維持しつつ不透明にする）。
enum AppColor {
    /// 区切り線（TimelineRowViewの1時間罫線など）。線なので半透明のままでよい。
    static let divider = Color.secondary.opacity(0.2)

    /// ブロック・カードの薄い塗り（背景と区別がつく程度）。不透明。
    /// elevatedFillGradientを大幅に薄くしたのに対しこちらは濃いままだと、ホームとタスク一覧・
    /// 選択の濃淡差が目立ちすぎるため、こちらも合わせて薄くしている。
    static let subtleFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.14, alpha: 1.0)
            : UIColor(white: 0.95, alpha: 1.0)
    })

    /// 配置ブロックなど、主役として少し強めに浮かせたい要素の塗り（subtleFillより一段濃い）。不透明。
    /// グラデーションの色差は控えめにしている。高さの低いブロックほど同じ色差が短い距離に
    /// 圧縮され、コントラストが強く見えてしまうため。
    static let elevatedFillGradient = LinearGradient(
        colors: [
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.10, alpha: 1.0)
                    : UIColor(white: 0.97, alpha: 1.0)
            }),
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.08, alpha: 1.0)
                    : UIColor(white: 0.95, alpha: 1.0)
            }),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// カードの境界線（最も細い線として使う想定）。単純な2色の直線的な変化ではなく、
    /// 上端にハイライトを集中させてそこからなだらかに減衰する3色構成にすることで、
    /// 「上から光が当たって反射している」ような、より自然な光沢感を出す。
    /// 背景（elevatedFillGradient等）をほぼ背景色に溶け込む薄さにしたため、カードの存在感は
    /// 主にこのエッジの質感が担っている。
    static let hairlineBorderGradient = LinearGradient(
        colors: [
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.55, alpha: 1.0)
                    : UIColor(white: 0.98, alpha: 1.0)
            }),
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.40, alpha: 1.0)
                    : UIColor(white: 0.88, alpha: 1.0)
            }),
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.34, alpha: 1.0)
                    : UIColor(white: 0.80, alpha: 1.0)
            }),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 補助情報のテキスト色（配置ブロック内の時間・メモなど）。標準の.secondaryだと、
    /// 背景をかなり薄くした結果コントラストが弱まって見えるため、.primaryより一段薄い
    /// 程度に留めて視認性を確保する。
    static let secondaryText = Color.primary.opacity(0.7)
}
