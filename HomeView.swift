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
    @State private var amount: String = ""
    @StateObject var locationmanager = LocationManager()  // 假設你有此class
    @State private var locationNote: String = ""
    @State private var isEditlocation: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // 類別選擇
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

                    // 內容與金額輸入
                    Group {
                        Text("內容：")
                            .font(.headline)

                        TextField("例如：電費、晚餐牛肉麵", text: $itemName)
                            .textFieldStyle(.roundedBorder)

                        Text("金額：")
                            .font(.headline)

                        TextField("例如：250", text: $amount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 地點輸入
                    Group {
                        Text("地點:")
                            .font(.headline)

                        TextField("目前地點", text: $locationNote, onEditingChanged: { editing in
                            isEditlocation = editing
                        })
                        .textFieldStyle(.roundedBorder)
                        .onReceive(locationmanager.$placeName) { newPlace in
                            if locationNote.isEmpty {
                                locationNote = newPlace
                            }
                        }
                        .onAppear {
                            if locationNote.isEmpty {
                                locationNote = locationmanager.placeName
                            }
                        }
                    }

                    // 日期選擇
                    Group {
                        Text("選擇日期：")
                            .font(.headline)

                        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }

                    // 新增按鈕
                    Button(action: {
                        guard let amountValue = Double(amount),
                              !itemName.trimmingCharacters(in: .whitespaces).isEmpty else {
                            return
                        }

                        let newRecord = ShoppingRecord(
                            id: nil,
                            name: itemName,
                            date: selectedDate,
                            category: selectedCategory,
                            amount: amountValue,
                            location: locationNote
                        )

                        store.addRecord(newRecord) { error in
                            if let error = error {
                                print("❌ 新增失敗: \(error.localizedDescription)")
                            } else {
                                // 新增成功，清空欄位
                                itemName = ""
                                amount = ""
                                locationNote = locationmanager.placeName
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
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

                    // 顯示紀錄
                    Text("支出項目")
                        .font(.headline)

                    if groupedRecords(for: selectedDate).isEmpty {
                        Text("尚無紀錄")
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ForEach(groupedRecords(for: selectedDate), id: \.key) { entry in
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
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("每日紀錄")
        }
        .hideKeyboardOnTap()
    }

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
