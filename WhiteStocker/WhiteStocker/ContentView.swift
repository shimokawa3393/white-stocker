//
//  ContentView.swift
//  WhiteStocker
//
//  Created by Shouhei Shimokawa on 2026/08/15.
//

import SwiftUI
import SwiftData

// TODO: Step 5でTimelineView実装後、ここをTimelineView()に差し替える
// 暫定的にTaskListViewを表示し、Step3のTask CRUDを単独で確認できるようにしている
struct ContentView: View {
    var body: some View {
        TaskListView()
    }
}

#Preview {
    ContentView()
}
