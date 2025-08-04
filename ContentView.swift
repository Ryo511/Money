//
//  ContentView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem {
                        Label("home", systemImage: "house")
                    }
                   
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Login", systemImage: "person.circle")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
