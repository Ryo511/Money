//
//  MoneyApp.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

//@main
//struct MoneyApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject private var authViewModel = AuthViewModel()
//    @StateObject private var store = ShoppingRecordStore()
//    
//    var body: some Scene {
//        WindowGroup {
//            if authViewModel.isLoggedIn {
//                ContentView()
//                    .environmentObject(authViewModel)
//                    .environmentObject(store)
//            } else {
//                LoginView()
//                    .environmentObject(authViewModel)
//            }
//        }
//    }
//}


@main
struct MoneyApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var shoppingStore = ShoppingRecordStore()

    init() {
        FirebaseApp.configure()  // 👈 這一行很重要！
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(authViewModel)
                .environmentObject(shoppingStore)
        }
    }
}
