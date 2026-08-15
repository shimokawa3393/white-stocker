//
//  TaskEditSheet.swift
//  WhiteStocker
//
//  タスクの新規作成・編集モーダル。両者を共通化する。
//

import SwiftUI
import SwiftData

struct TaskEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 編集対象。nilなら新規作成
    private let editingTask: TaskItem?

    @State private var name: String
    @State private var memo: String
    @State private var durationMin: Int

    init(editingTask: TaskItem? = nil) {
        self.editingTask = editingTask
        _name = State(initialValue: editingTask?.name ?? "")
        _memo = State(initialValue: editingTask?.memo ?? "")
        _durationMin = State(initialValue: editingTask?.durationMin ?? 30)
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("タスク名") {
                    TextField("タスク名", text: $name)
                }
                Section("詳細メモ") {
                    // NOTE: TextField(text:axis:.vertical) は日本語IME変換確定時のEnterで
                    // 入力内容が消えるSwiftUIの既知の不具合があるためTextEditorを使う
                    ZStack(alignment: .topLeading) {
                        if memo.isEmpty {
                            Text("メモ（任意）")
                                .foregroundStyle(.tertiary)
                                .padding(.top, Spacing.sm)
                                .padding(.leading, Spacing.xs)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $memo)
                            .frame(minHeight: 100, maxHeight: 160)
                    }
                }
                Section("所要時間") {
                    Picker("所要時間", selection: $durationMin) {
                        ForEach(DurationFormatter.range, id: \.self) { minutes in
                            Text(DurationFormatter.label(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            // ドラッグ操作でキーボードが追従して閉じるようにする。Formは背景全体に
            // 直接タップジェスチャーを仕込むのが技術的に難しいため、この標準APIで対応する。
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editingTask == nil ? "タスクを追加" : "タスクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!isNameValid)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMemo = trimmedMemo.isEmpty ? nil : trimmedMemo

        if let task = editingTask {
            task.name = trimmedName
            task.memo = normalizedMemo
            task.durationMin = durationMin
        } else {
            let newTask = TaskItem(
                name: trimmedName,
                memo: normalizedMemo,
                durationMin: durationMin
            )
            modelContext.insert(newTask)
        }
        dismiss()
    }
}

#Preview {
    TaskEditSheet()
        .modelContainer(for: [TaskItem.self, Placement.self], inMemory: true)
}
