//
//  DesignTokens.swift
//  WhiteStocker
//
//  デザインの一貫性を保つための共通トークン（余白・角丸・色階調）。
//  各Viewでその場しのぎの数値をハードコードするのではなく、ここに集約して参照する。
//  モノトーン方針（設計書v0スコープ）を維持しつつ、階調に意味を持たせる。
//

import SwiftUI

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
    static let small: CGFloat = 8
    /// カード・シートのコンテナなど
    static let medium: CGFloat = 12
}

/// モノトーン方針の中での色階調。用途ごとに意味を持たせて命名する。
enum AppColor {
    /// 最も薄い区切り線（TimelineRowViewの罫線など、存在を主張しすぎない境界）
    static let divider = Color.secondary.opacity(0.15)
    /// ブロック・カードの枠線
    static let border = Color.primary.opacity(0.25)
    /// ブロック・カードの薄い塗り（背景と区別がつく程度）
    static let subtleFill = Color.primary.opacity(0.06)
}
