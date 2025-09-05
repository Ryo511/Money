//
//  ContentView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ShoppingRecordStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(NSLocalizedString("Home", comment: "首頁"), systemImage: "house") }
                .tag(0)

            HistoryView()
                .tabItem { Label(NSLocalizedString("History", comment: "歷史紀錄"), systemImage: "clock") }
                .tag(1)

            GroupListView()
                .tabItem { Label(NSLocalizedString("Group", comment: "群組"), systemImage: "person.crop.circle") }
                .tag(2)

            SettingsView()
                .tabItem { Label(NSLocalizedString("Login", comment: "設定"), systemImage: "person.circle") }
                .tag(3)
        }
        .onChange(of: selectedTab) { newValue in
            // 點 Tab 可以做額外操作，例如回到群組列表初始頁
            if newValue == 2 {
                NotificationCenter.default.post(name: .groupTabTapped, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let groupTabTapped = Notification.Name("groupTabTapped")
}

#Preview {
    ContentView()
}
