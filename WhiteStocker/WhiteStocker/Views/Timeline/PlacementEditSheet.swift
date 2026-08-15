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

    private let quickOptions = [15, 30, 45, 60]

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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("タスク", value: placement.task.name)
                }
                Section("開始時刻") {
                    HStack {
                        Button {
                            adjustStartTime(by: -15)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        Spacer()
                        Text(timeText(startTime))
                            .font(.title3)
                            .monospacedDigit()
                        Spacer()
                        Button {
                            adjustStartTime(by: 15)
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
                Section("所要時間") {
                    HStack {
                        ForEach(quickOptions, id: \.self) { minutes in
                            Button {
                                durationMin = minutes
                            } label: {
                                Text("\(minutes)分")
                            }
                            .buttonStyle(.bordered)
                            .tint(durationMin == minutes ? .accentColor : .secondary)
                        }
                    }
                }
                if hasConflict {
                    Section {
                        Text("他の配置と時間が重なっています")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else if durationMin > maxDuration {
                    Section {
                        Text("この開始時刻では最大\(maxDuration)分までしか確保できません")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Button("この配置を削除", role: .destructive) {
                        delete()
                    }
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

    private func adjustStartTime(by minutes: Int) {
        let calendar = Calendar.current
        guard let newStart = calendar.date(byAdding: .minute, value: minutes, to: startTime) else { return }
        let startOfDay = calendar.startOfDay(for: placement.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        guard newStart >= startOfDay, newStart < endOfDay else { return }
        startTime = newStart
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
