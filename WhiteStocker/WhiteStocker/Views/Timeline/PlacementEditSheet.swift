//
//  PlacementEditSheet.swift
//  WhiteStocker
//
//  既存Placementの編集モーダル。startTime / durationMinの編集、および削除ができる。
//  削除は物理削除でよい（Placementは在庫ではなく配置の実体のため）。
//

import SwiftUI
import SwiftData

struct PlacementEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let placement: Placement
    /// その日の全Placement（自分自身を含む）。重複判定のため自分を除いて使う
    let allPlacementsOfDay: [Placement]

    @State private var startTime: Date
    @State private var durationMin: Int

    init(placement: Placement, allPlacementsOfDay: [Placement]) {
        self.placement = placement
        self.allPlacementsOfDay = allPlacementsOfDay
        _startTime = State(initialValue: placement.startTime)
        _durationMin = State(initialValue: placement.durationMin)
    }

    private var otherPlacements: [Placement] {
        allPlacementsOfDay.filter { $0.id != placement.id }
    }

    private var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: durationMin, to: startTime) ?? startTime
    }

    private var hasConflict: Bool {
        SlotFinder.hasConflict(start: startTime, end: endTime, existingPlacements: otherPlacements)
    }

    private var maxDuration: Int {
        SlotFinder.maxAvailableDuration(from: startTime, existingPlacements: otherPlacements)
    }

    private let minuteOptions = [0, 15, 30, 45]

    private var hourBinding: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.hour, from: startTime) },
            set: { newHour in
                startTime = Self.settingComponent(.hour, to: newHour, on: startTime)
            }
        )
    }

    private var minuteBinding: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.minute, from: startTime) },
            set: { newMinute in
                startTime = Self.settingComponent(.minute, to: newMinute, on: startTime)
            }
        )
    }

    private static func settingComponent(_ component: Calendar.Component, to value: Int, on date: Date) -> Date {
        let calendar = Calendar.current
        var hour = calendar.component(.hour, from: date)
        var minute = calendar.component(.minute, from: date)
        if component == .hour {
            hour = value
        } else if component == .minute {
            minute = value
        }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("タスク", value: placement.task.name)
                }
                Section("開始時刻") {
                    HStack {
                        Picker("時", selection: hourBinding) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("start-time-hour-picker")

                        Text(":")
                            .font(.title2)

                        Picker("分", selection: minuteBinding) {
                            ForEach(minuteOptions, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("start-time-minute-picker")
                    }
                    .frame(height: 120)
                }
                Section("所要時間") {
                    Picker("所要時間", selection: $durationMin) {
                        ForEach(DurationFormatter.range, id: \.self) { minutes in
                            Text(DurationFormatter.label(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .accessibilityIdentifier("duration-picker")
                }
                if hasConflict {
                    Section {
                        WarningLabel(message: "他の配置と時間が重なっています")
                    }
                } else if durationMin > maxDuration {
                    Section {
                        WarningLabel(message: "この開始時刻では最大\(maxDuration)分までしか確保できません")
                    }
                }
                Section {
                    Button("この配置を削除", role: .destructive) {
                        delete()
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("配置を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(hasConflict || durationMin <= 0)
                }
            }
        }
    }

    private func save() {
        placement.startTime = startTime
        placement.durationMin = durationMin
        dismiss()
    }

    private func delete() {
        modelContext.delete(placement)
        dismiss()
    }
}
