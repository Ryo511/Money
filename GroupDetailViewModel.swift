//
//  GroupDetailViewModel.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/11/28.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class GroupDetailViewModel: ObservableObject {
    @Published var group: ExpenseGroup
    @Published var expenses: [Expense] = []
    @Published var balances: [String: Double] = [:]
    @Published var friends: [AppUser] = []

    let currentUserId: String
    private var expensesListener: ListenerRegistration?

    init(group: ExpenseGroup) {
        self.group = group
        self.currentUserId = Auth.auth().currentUser?.uid ?? ""
        startListeningExpenses()
        loadFriends()
    }

    deinit {
        expensesListener?.remove()
    }

    // MARK: - Computed

    var myBalance: Double? {
        balances[currentUserId]
    }

    func memberName(for uid: String) -> String {
        group.members.first { $0.id == uid }?.name ?? "未知"
    }

    // MARK: - Firestore

    private func startListeningExpenses() {
        guard let groupId = group.id else { return }

        expensesListener = FirebaseManager.shared.db
            .collection("groups")
            .document(groupId)
            .collection("expenses")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ 讀取群組支出失敗：\(error.localizedDescription)")
                    return
                }

                self.expenses = snapshot?.documents.compactMap {
                    try? $0.data(as: Expense.self)
                } ?? []

                self.calculateBalances()
            }
    }

    func stopListening() {
        expensesListener?.remove()
        expensesListener = nil
    }

    private func calculateBalances() {
        guard let groupId = group.id else { return }
        FirebaseManager.shared.calculateBalances(for: groupId) { [weak self] result in
            DispatchQueue.main.async {
                self?.balances = result
            }
        }
    }

    func deleteExpense(_ expense: Expense) {
        FirebaseManager.shared.deleteExpense(groupId: group.id ?? "", expense: expense) { error in
            if let error = error {
                print("刪除失敗：\(error.localizedDescription)")
            }
            // 不用手動更新 expenses，listener 會處理
        }
    }

    private func loadFriends() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUid).collection("friends")
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                if let docs = snapshot?.documents {
                    self.friends = docs.map { doc in
                        AppUser(
                            id: doc.documentID,
                            name: doc["name"] as? String ?? "",
                            email: doc["email"] as? String ?? ""
                        )
                    }
                }
            }
    }
}
