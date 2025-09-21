//
//  AddExpenseView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/31.
//

import SwiftUI
import FirebaseAuth

struct AddExpenseView: View {
    var group: ExpenseGroup
    var onComplete: ((Expense) -> Void)
    
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var amount = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("支出標題")) {
                    TextField("例如：飯店住宿", text: $title)
                }
                
                Section(header: Text("金額")) {
                    TextField("金額", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button(action: {
                        guard let amt = Double(amount), !title.isEmpty else { return }
                        guard let currentUid = Auth.auth().currentUser?.uid else { return }
                        
                        let expense = Expense(
                            title: title,
                            amount: amt,
                            paidBy: currentUid,
                            splitMethod: "equal",
                            customSplit: nil,
                            date: Date()
                        )
                        
                        FirebaseManager.shared.addExpense(to: group.id ?? "", expense: expense) { error in
                            if let error = error {
                                print("新增支出失敗: \(error.localizedDescription)")
                            } else {
                                onComplete(expense)
                                dismiss()
                            }
                        }
                    }) {
                        Text("新增支出")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }
}
