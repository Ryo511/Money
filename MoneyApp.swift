//
//  MoneyApp.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

@main
struct MoneyApp: App {
    
    @StateObject private var store = ShoppingRecordStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
