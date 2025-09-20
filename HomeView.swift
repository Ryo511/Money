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
                    emptyStateView
                } else {
                    recordListView
                }
                
                addButton
            }
            .navigationTitle("每日紀錄")
            .sheet(isPresented: $showAddSheet) {
                AddRecordView()
                    .environmentObject(store)
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "wallet.pass")
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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .padding()
    }
    
    var recordListView: some View {
        ScrollView {
            ForEach(groupedRecords(for: Date()), id: \.key) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text("📂 \(entry.key)")
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
    
    var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
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
    
    func groupedRecords(for date: Date) -> [(key: String, value: [ShoppingRecord])] {
        let calendar = Calendar.current
        let filtered = store.records.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let grouped = Dictionary(grouping: filtered, by: { $0.category })
        return grouped.sorted { $0.key < $1.key }
    }
}

#Preview {
    HomeView()
        .environmentObject(ShoppingRecordStore())
}
