//
//  SlotPickerSheet.swift
//  WhiteStocker
//
//  Rowタップ時の配置フロー：空きスロット提示 → Task選択 → duration確定 → Placement生成
//

import SwiftUI
import SwiftData

struct SlotPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let rowStart: Date
    let rowEnd: Date
    let date: Date
    let existingPlacements: [Placement]

    @Query(
        filter: #Predicate<TaskItem> { $0.deletedAt == nil },
        sort: \TaskItem.createdAt,
        order: .reverse
    )
    private var tasks: [TaskItem]

    @State private var path: [Destination] = []

    private var availableSlots: [DateInterval] {
        SlotFinder.availableSlots(rowStart: rowStart, rowEnd: rowEnd, existingPlacements: existingPlacements)
    }

    var body: some View {
        NavigationStack(path: $path) {
            rootView
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .taskPicker(let slotStart):
                        taskPickerView(slotStart: slotStart)
                    case .durationConfirm(let slotStart, let task):
                        DurationConfirmView(
                            slotStart: slotStart,
                            task: task,
                            existingPlacements: existingPlacements,
                            onConfirm: { start, durationMin in
                                createPlacement(task: task, start: start, durationMin: durationMin)
                            }
                        )
                    }
                }
        }
    }

    /// 空きスロットが1件だけなら「時間を選択」画面を経由せず直接タスク選択から始める。
    /// 複数の空き区間から選ぶ必要がある場合のみslotListViewを表示する。
    @ViewBuilder
    private var rootView: some View {
        if availableSlots.count == 1, let onlySlot = availableSlots.first {
            taskPickerView(slotStart: onlySlot.start)
        } else {
            slotListView
        }
    }

    @ViewBuilder
    private var slotListView: some View {
        Group {
            if availableSlots.isEmpty {
                ContentUnavailableView(
                    "空きがありません",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("この時間帯にはすでに予定が詰まっています")
                )
            } else {
                List(availableSlots, id: \.start) { slot in
                    Button {
                        path.append(.taskPicker(slotStart: slot.start))
                    } label: {
                        Text(slotLabel(slot))
                    }
                }
            }
        }
        .navigationTitle("時間を選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func taskPickerView(slotStart: Date) -> some View {
        Group {
            if tasks.isEmpty {
                ContentUnavailableView(
                    "タスクがありません",
                    systemImage: "tray",
                    description: Text("先にタスク一覧から追加してください")
                )
            } else {
                List(tasks) { task in
                    Button {
                        path.append(.durationConfirm(slotStart: slotStart, task: task))
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.name)
                            Text("\(task.durationMin)分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("タスクを選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // rootViewとして直接表示される場合（空きスロット1件の自動スキップ時）に
            // 閉じる手段を確保するため、常にキャンセルボタンを表示する
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
        }
    }

    private func slotLabel(_ slot: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: slot.start))〜"
    }

    private func createPlacement(task: TaskItem, start: Date, durationMin: Int) {
        let placement = Placement(task: task, date: date, startTime: start, durationMin: durationMin)
        modelContext.insert(placement)
        dismiss()
    }

    private enum Destination: Hashable {
        case taskPicker(slotStart: Date)
        case durationConfirm(slotStart: Date, task: TaskItem)
    }
}

/// 所要時間の確認・クイック上書き画面
private struct DurationConfirmView: View {
    let slotStart: Date
    let task: TaskItem
    let existingPlacements: [Placement]
    let onConfirm: (Date, Int) -> Void

    @State private var durationMin: Int

    private let quickOptions = [15, 30, 45, 60]

    init(
        slotStart: Date,
        task: TaskItem,
        existingPlacements: [Placement],
        onConfirm: @escaping (Date, Int) -> Void
    ) {
        self.slotStart = slotStart
        self.task = task
        self.existingPlacements = existingPlacements
        self.onConfirm = onConfirm
        _durationMin = State(initialValue: task.durationMin)
    }

    private var maxDuration: Int {
        SlotFinder.maxAvailableDuration(from: slotStart, existingPlacements: existingPlacements)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("タスク", value: task.name)
                LabeledContent("開始", value: timeText(slotStart))
                LabeledContent("所要時間", value: "\(durationMin)分")
            }
            Section("所要時間を変更") {
                HStack {
                    ForEach(quickOptions, id: \.self) { minutes in
                        Button {
                            durationMin = minutes
                        } label: {
                            Text("\(minutes)分")
                        }
                        .buttonStyle(.bordered)
                        .tint(durationMin == minutes ? .accentColor : .secondary)
                        .disabled(minutes > maxDuration)
                    }
                }
            }
            if durationMin > maxDuration {
                Section {
                    Text("この開始時刻では最大\(maxDuration)分までしか確保できません")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("時間を確認")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("配置する") {
                    onConfirm(slotStart, durationMin)
                }
                .disabled(durationMin > maxDuration || durationMin <= 0)
            }
        }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
