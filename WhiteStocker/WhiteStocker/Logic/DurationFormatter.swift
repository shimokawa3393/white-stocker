//
//  DurationFormatter.swift
//  WhiteStocker
//
//  所要時間（分）の表示用フォーマットと、Wheel Pickerで使う15分刻みの候補リストを提供する。
//  TaskEditSheet / PlacementEditSheet の両方で使う共通ロジック。
//

import Foundation

enum DurationFormatter {
    /// 15分刻みの候補（15分〜8時間）
    static let stepMinutes = 15
    static let range: [Int] = stride(from: 15, through: 480, by: stepMinutes).map { $0 }

    /// 分を「○時間○分」表記に変換する
    static func label(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours)時間" : "\(hours)時間\(remainder)分"
    }
}
