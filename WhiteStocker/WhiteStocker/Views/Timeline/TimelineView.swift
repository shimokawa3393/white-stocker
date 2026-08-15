//
//  TimelineView.swift
//  WhiteStocker
//
//  ホーム画面。縦は1時間刻みRow（ScrollView）、横は日付ページング（TabView.page）。
//  カレンダーピッカー等の遠距離ジャンプは持たない（横スクロールのみ、設計書で明示的に不採用）。
//

import SwiftUI
import SwiftData
import Combine

struct TimelineView: View {
    /// 前後365日をページング範囲とする（無限スクロールは不採用、有限範囲で十分と判断）
    private let dayOffsetRange = Array(-365...365)

    @State private var selectedOffset: Int = 0
    @State private var isPresentingTaskList = false
    @AppStorage("colorSchemePreference") private var colorSchemePreferenceRaw: String = AppColorSchemePreference.system.rawValue

    private var colorSchemePreference: AppColorSchemePreference {
        AppColorSchemePreference(rawValue: colorSchemePreferenceRaw) ?? .system
    }

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("外観", selection: $colorSchemePreferenceRaw) {
                            ForEach(AppColorSchemePreference.allCases, id: \.self) { preference in
                                Label(preference.label, systemImage: preference.systemImage)
                                    .tag(preference.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: colorSchemePreference.systemImage)
                    }
                }
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
    @State private var now: Date = .now
    /// DayTimelineView全体（ScrollView含む）の利用可能幅。GeometryReaderで計測する。
    @State private var outerWidth: CGFloat = 0

    private static let contentLeadingInset: CGFloat = TimelineRowView.labelWidth + TimelineRowView.labelSpacing
    /// 左右の余白。ZStackにはこの分を差し引いた幅を明示的に指定し、その外側にpaddingとして
    /// 同じ値を加える。padding()だけでZStackを縮小しようとすると、内部にmaxWidth: .infinityの
    /// 子（TimelineRowView）を持つ関係でSwiftUIのレイアウト計算がずれ、画面端をはみ出すことが
    /// あったため、幅を明示的に固定する方式にしている。
    private static let horizontalMargin: CGFloat = Spacing.sm
    /// 現在時刻インジケーターの更新用。アプリ全体で1本のタイマーを共有する
    private static let timeUpdateTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var contentWidth: CGFloat {
        max(outerWidth - Self.horizontalMargin * 2, 0)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var placementLayoutItems: [PlacementLayoutItem] {
        PlacementLayout.layout(for: placements)
    }

    init(date: Date) {
        self.date = date
        let normalizedDate = Calendar.current.startOfDay(for: date)
        _placements = Query(
            filter: #Predicate<Placement> { $0.date == normalizedDate },
            sort: \Placement.startTime
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            Button {
                                pickerContext = SlotPickerContext(
                                    rowStart: rowDate(hour: hour),
                                    rowEnd: rowDate(hour: hour + 1)
                                )
                            } label: {
                                TimelineRowView(hour: hour)
                            }
                            .buttonStyle(PressableRowStyle())
                            .id(hour)
                        }
                    }

                    // contentWidthが確定する前（初回描画の1フレーム目）に配置ブロックを生成すると、
                    // 幅0でレイアウトされたボタンのタップ領域が後から正しく更新されないことがあるため、
                    // 確定するまでは描画しない。
                    //
                    // 重なり順は「Row罫線 → 配置ブロックの背景（タップ領域） → 現在時刻線 → 配置ブロックの
                    // テキスト」。現在時刻線を背景とテキストの間に挟むことで、線がテキストに重なって
                    // 読みにくくなることも、ブロックの背景に完全に隠れて消えてしまうことも防いでいる。
                    if contentWidth > 0 {
                        ForEach(placementLayoutItems, id: \.placement.id) { item in
                            let blockView = PlacementBlockView(
                                layout: item,
                                contentLeadingInset: Self.contentLeadingInset,
                                contentWidth: max(contentWidth - Self.contentLeadingInset, 0)
                            )
                            Button {
                                editingPlacement = item.placement
                            } label: {
                                blockView.background
                            }
                            .buttonStyle(PressableRowStyle())
                            .offset(x: blockView.xOffset, y: blockView.yOffset)
                        }
                    }

                    if isToday {
                        CurrentTimeIndicatorView(
                            contentLeadingInset: Self.contentLeadingInset,
                            currentTime: now
                        )
                    }

                    if contentWidth > 0 {
                        ForEach(placementLayoutItems, id: \.placement.id) { item in
                            let blockView = PlacementBlockView(
                                layout: item,
                                contentLeadingInset: Self.contentLeadingInset,
                                contentWidth: max(contentWidth - Self.contentLeadingInset, 0)
                            )
                            blockView.content
                                .offset(x: blockView.xOffset, y: blockView.yOffset)
                        }
                    }
                }
                .frame(width: contentWidth > 0 ? contentWidth : nil, height: TimelineRowView.rowHeight * 24)
                .padding(.horizontal, Self.horizontalMargin)
            }
            .onAppear {
                // 今日のページのみ、現在時刻付近を画面中央に自動スクロール。
                // 上端/下端に近い時刻の場合はScrollViewの範囲制約により自然にその端で止まる。
                // onAppear直後はScrollViewのレイアウトがまだ確定していないことがあり、
                // その状態でscrollToすると意図しない位置（ナビゲーションバーの裏など）に
                // 着地することがあるため、1フレーム遅延させてから実行する。
                guard isToday else { return }
                let currentHour = Calendar.current.component(.hour, from: .now)
                DispatchQueue.main.async {
                    proxy.scrollTo(currentHour, anchor: .center)
                }
            }
            .onReceive(Self.timeUpdateTimer) { newTime in
                now = newTime
            }
        }
        // DayTimelineView全体（NavigationBarの裏に回り込まない、Safe Area内の実際の
        // コンテンツ領域）の幅をここで計測する。ZStackの直接の子としてGeometryReaderを
        // 置くとSafe Areaを考慮しない座標系になり00:00がヘッダーの裏に隠れる不具合が
        // あったため、その教訓を踏まえてこの外側の.backgroundで取得している。
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { outerWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, newValue in
                        outerWidth = newValue
                    }
            }
        )
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
