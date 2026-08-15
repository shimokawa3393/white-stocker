//
//  TaskListView.swift
//  WhiteStocker
//
//  タスクの在庫一覧。CRUDのコア画面。
//

import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<TaskItem> { $0.deletedAt == nil },
        sort: \TaskItem.createdAt,
        order: .reverse
    )
    private var tasks: [TaskItem]

    @State private var isPresentingNewTask = false
    @State private var editingTask: TaskItem?

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "タスクがありません",
                        systemImage: "tray",
                        description: Text("右上の＋からタスクを追加できます")
                    )
                } else {
                    List {
                        ForEach(tasks) { task in
                            Button {
                                editingTask = task
                            } label: {
                                taskRow(task)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }
            }
            .navigationTitle("タスク一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewTask = true
                    } label: {
                        Label("タスクを追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewTask) {
                TaskEditSheet()
            }
            .sheet(item: $editingTask) { task in
                TaskEditSheet(editingTask: task)
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.name)
                .font(.body)
                .foregroundStyle(.primary)
            if let memo = task.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text("\(task.durationMin)分")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// スワイプ削除は論理削除。物理削除しない（過去のPlacementの参照切れを防ぐため）
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            tasks[index].deletedAt = .now
        }
    }
}

#Preview {
    TaskListView()
        .modelContainer(for: [TaskItem.self, Placement.self], inMemory: true)
}
