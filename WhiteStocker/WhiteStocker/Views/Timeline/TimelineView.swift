//
//  TimelineView.swift
//  WhiteStocker
//
//  ホーム画面。縦は1時間刻みRow（ScrollView）、横は日付ページング（TabView.page）。
//  カレンダーピッカー等の遠距離ジャンプは持たない（横スクロールのみ、設計書で明示的に不採用）。
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    /// 前後365日をページング範囲とする（無限スクロールは不採用、有限範囲で十分と判断）
    private let dayOffsetRange = Array(-365...365)

    @State private var selectedOffset: Int = 0
    @State private var isPresentingTaskList = false

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedOffset) {
                ForEach(dayOffsetRange, id: \.self) { offset in
                    DayTimelineView(date: date(for: offset))
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingTaskList = true
                    } label: {
                        Label("タスク一覧", systemImage: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $isPresentingTaskList) {
                TaskListView()
            }
        }
    }

    private var titleText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date(for: selectedOffset))
    }

    private func date(for offset: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: offset,
            to: Calendar.current.startOfDay(for: .now)
        ) ?? .now
    }
}

/// 1日分のタイムライン（0:00〜23:00の24Row、縦スクロール）
private struct DayTimelineView: View {
    let date: Date

    @Query private var placements: [Placement]
    @State private var pickerContext: SlotPickerContext?
    @State private var editingPlacement: Placement?

    private static let contentLeadingInset: CGFloat = TimelineRowView.labelWidth + TimelineRowView.labelSpacing

    init(date: Date) {
        self.date = date
        let normalizedDate = Calendar.current.startOfDay(for: date)
        _placements = Query(
            filter: #Predicate<Placement> { $0.date == normalizedDate },
            sort: \Placement.startTime
        )
    }

    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            TimelineRowView(hour: hour)
                                .onTapGesture {
                                    pickerContext = SlotPickerContext(
                                        rowStart: rowDate(hour: hour),
                                        rowEnd: rowDate(hour: hour + 1)
                                    )
                                }
                        }
                    }

                    ForEach(PlacementLayout.layout(for: placements), id: \.placement.id) { item in
                        PlacementBlockView(
                            layout: item,
                            contentLeadingInset: Self.contentLeadingInset,
                            contentWidth: max(geometry.size.width - Self.contentLeadingInset, 0)
                        )
                        .onTapGesture {
                            editingPlacement = item.placement
                        }
                    }
                }
            }
            .frame(height: TimelineRowView.rowHeight * 24)
        }
        .sheet(item: $pickerContext) { context in
            SlotPickerSheet(
                rowStart: context.rowStart,
                rowEnd: context.rowEnd,
                date: normalizedDate,
                existingPlacements: placements
            )
        }
        .sheet(item: $editingPlacement) { placement in
            PlacementEditSheet(placement: placement, allPlacementsOfDay: placements)
        }
    }

    private var normalizedDate: Date {
        Calendar.current.startOfDay(for: date)
    }

    private func rowDate(hour: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hour, to: normalizedDate) ?? normalizedDate
    }
}

private struct SlotPickerContext: Identifiable {
    let id = UUID()
    let rowStart: Date
    let rowEnd: Date
}

#Preview {
    TimelineView()
        .modelContainer(for: [TaskItem.self, Placement.self], inMemory: true)
}
