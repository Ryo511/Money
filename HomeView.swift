//
//  HomeView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ShoppingRecordStore
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if store.records.isEmpty {
                    // 空白狀態畫面
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "wallet.pass") // 插圖
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.blue.opacity(0.7))
                        
                        VStack(spacing: 8) {
                            Text("今天還沒有支出紀錄喔！")
                                .font(.title3)
                                .foregroundColor(.gray)
                            Text("點擊右下角 + 開始新增支出")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // 模擬示範支出卡片
                        VStack(spacing: 12) {
                            Text("示範支出")
                                .font(.headline)
                            HStack {
                                Text("🛒 早餐")
                                Spacer()
                                Text("NT$100")
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            
                            HStack {
                                Text("🚌 交通")
                                Spacer()
                                Text("NT$50")
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6).opacity(0.3))
                    .cornerRadius(12)
                    .padding()
                } else {
                    // 有支出紀錄時，顯示分組列表
                    ScrollView {
                        ForEach(groupedRecords(for: Date()), id: \.key) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("📂 \(NSLocalizedString(entry.key, comment: "分類名稱"))")
                                    .font(.headline)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)

                                ForEach(entry.value) { record in
                                    HStack {
                                        Text("🛒 \(record.name)")
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text("💰 NT$\(String(format: "%.0f", record.amount))")
                                                .foregroundColor(.gray)
                                            Text("📍 \(record.location)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top)
                }
                
                // 🔹 右下角浮動按鈕
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("DailyRecords", comment: "每日紀錄標題"))
            .sheet(isPresented: $showAddSheet) {
                AddRecordView()
                    .environmentObject(store)
            }
        }
    }
    
    // 分組函式
    func groupedRecords(for date: Date) -> [(key: String, value: [ShoppingRecord])] {
        let calendar = Calendar.current
        let filtered = store.records.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        return grouped.sorted { $0.key < $1.key }
    }
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    HomeView()
}
