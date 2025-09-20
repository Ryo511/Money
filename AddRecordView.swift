//
//  AddRecordView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/31.
//

import SwiftUI

struct AddRecordView: View {
    @EnvironmentObject var store: ShoppingRecordStore
    @Environment(\.dismiss) var dismiss
    
    @State private var itemName: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: String = NSLocalizedString("帳單", comment: "預設支出類別")
    let expenseTypes = [
        NSLocalizedString("帳單", comment: "支出類別"),
        NSLocalizedString("購物", comment: "支出類別"),
        NSLocalizedString("電話費", comment: "支出類別"),
        NSLocalizedString("交通", comment: "支出類別"),
        NSLocalizedString("飲食", comment: "支出類別"),
        NSLocalizedString("娛樂", comment: "支出類別")
    ]
    @State private var amount: String = ""
    @StateObject var locationmanager = LocationManager()
    @State private var locationNote: String = ""
    @State private var isEditlocation: Bool = false
    
    @FocusState private var focusedField: Field?
    enum Field { case name, amount, location }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Category", comment: "支出類別"))) {
                    Picker(NSLocalizedString("Category", comment: "類別"), selection: $selectedCategory) {
                        ForEach(expenseTypes, id: \.self) { category in
                            Text(category)
                        }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Content", comment: "內容"))) {
                    TextField(NSLocalizedString("ExpenseExample", comment: "例如內容"), text: $itemName)
                        .textContentType(.none) // 內容自由輸入
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .amount }
                }
                
                Section(header: Text(NSLocalizedString("Amount", comment: "金額"))) {
                    TextField(NSLocalizedString("AmountExample", comment: "例如金額"), text: $amount)
                        .keyboardType(.decimalPad)
                        .textContentType(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .amount)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button(NSLocalizedString("Done", comment: "完成")) {
                                    focusedField = .location
                                }
                            }
                        }
                }
                
                Section(header: Text(NSLocalizedString("Place", comment: "地點"))) {
                    TextField(NSLocalizedString("PlaceExample", comment: "目前地點"), text: $locationNote, onEditingChanged: { editing in
                        isEditlocation = editing
                    })
                    .textContentType(.fullStreetAddress) // 或 .locationName 視需求
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .location)
                    .onSubmit { focusedField = nil }
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
                
                Section(header: Text(NSLocalizedString("Date", comment: "日期"))) {
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
            }
            .navigationTitle(NSLocalizedString("AddRecordTitle", comment: "新增紀錄"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "取消")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Save", comment: "儲存")) {
                        saveRecord()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty || Double(amount) == nil)
                }
            }
            .onAppear {
                // 預設先聚焦到名稱
                focusedField = .name
            }
        }
    }
    
    private func saveRecord() {
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
        
        store.addRecord(newRecord)
        dismiss()
    }
}

