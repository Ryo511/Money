//
//  TabView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var store: ShoppingRecordStore
    @State private var itemName: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: String = "帳單"
    let expenseTypes = ["帳單", "購物", "電話費", "交通", "飲食", "娛樂"]
    @State private var selectedType: String = "帳單"
    @State private var amount: String = ""
    @StateObject var locationmanager = LocationManager()
    @State private var locationNote: String = ""
    @State private var isEditlocation: Bool = false
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("支出類別：")
                        .font(.headline)
                    
                    Menu {
                        ForEach(expenseTypes, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                }
                
                Text("內容：")
                    .font(.headline)
                
                TextField("例如：電費、晚餐牛肉麵", text: $itemName)
                    .textFieldStyle(.roundedBorder)
                Text("金額：")
                    .font(.headline)
                
                TextField("例如：250", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                
                Text("地點: ")
                    .font(.headline)
                TextField("目前地點", text: $locationNote, onEditingChanged: { editing in
                    isEditlocation = editing
                })
                    .textFieldStyle(.roundedBorder)
                    .onReceive(locationmanager.$placeName) { newPlace in
                            // 只有當 locationNote 是空的才自動填入（避免覆蓋使用者手動修改）
                            if locationNote.isEmpty {
                                locationNote = newPlace
                            }
                        }
                    .onAppear {
                        if locationNote.isEmpty {
                            locationNote = locationmanager.placeName
                        }
                    }
                
                Text("選擇日期：")
                    .font(.headline)
                
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                
                Button(action: {
                    if let amountValue = Double(amount),
                       !itemName.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.addRecord(name: itemName, date: selectedDate, category: selectedCategory, amount: amountValue, location: locationNote)
                        
                            itemName = "" // 清空輸入欄
                            amount = ""
    //                        selectedDate = Date() // 回到今天
                            locationNote = ""
                        
                            locationNote = locationmanager.placeName
                            
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                    }
                }) {
                    Text("新增紀錄")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Divider()
                
                Text("支出項目")
                    .font(.headline)
                
                List {
                    //                    ForEach(store.records) { record in
                    //                        HStack {
                    //                            Text(record.name)
                    //                            Spacer()
                    //                            Text(formattedDate(record.date))
                    //                                .foregroundColor(.gray)
                    //                                .font(.subheadline)
                    //                        }
                    //                    }
                    ForEach(groupedRecords(for: selectedDate), id: \.key) { category, items in
                        Section(header: Text("📂 \(category)")) {
                            ForEach(items) { record in
                                HStack {
                                    Text("🛒 \(record.name)")
                                    Spacer()
                                    
                                    Text("💰 NT$\(String(format: "%.0f", record.amount))")
                                        .foregroundStyle(.gray)
                                    
                                    Text("📍 \(record.location)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("每日紀錄")
        }
        .hideKeyboardOnTap()
    }
    
    //    func formattedDate(_ date: Date) -> String {
    //        let formatter = DateFormatter()
    //        formatter.dateFormat = "yyyy/MM/dd"
    //        return formatter.string(from: date)
    //    }
    func groupedRecords(for date: Date) -> [(key: String, value: [ShoppingRecord])] {
        let todayRecords = store.records(for: date)
        let grouped = Dictionary(grouping: todayRecords, by: { $0.category })
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
    HomeView().environmentObject(ShoppingRecordStore())
}
