//
//  GroupDetailView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/31.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroupDetailView: View {
    @State var group: ExpenseGroup
    @State private var expenses: [Expense] = []
    @State private var balances: [String: Double] = [:]
    @State private var showingAddExpense = false
    @State private var showingAddMember = false
    @State private var showingAllBalances = false
    @State private var friends: [AppUser] = [] // 好友列表
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        VStack {
            // 成員列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(group.members) { member in
                        VStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(Text(member.name.prefix(1)))
                            Text(member.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
            }

            Divider()

            // 支出列表
            List {
                ForEach(expenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title)
                                .bold()
                            Text("付款者: \(memberName(for: expense.paidBy))")
                                .font(.caption)
                        }
                        Spacer()
                        Text("NT$\(Int(expense.amount))")
                            .bold()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteExpense(expense)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                }
            }

            Divider()

            // 只顯示「我的應付/應收」摘要卡片
            if let myBalance = balances[currentUserId] {
                VStack {
                    Text("我的分帳結果")
                        .font(.headline)
                        .padding(.bottom, 4)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(myBalance >= 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .frame(height: 100)
                            .shadow(radius: 2)

                        VStack {
                            Text(myBalance >= 0 ? "應收" : "應付")
                                .font(.title3)
                                .bold()
                            Text("NT$\(Int(abs(myBalance)))")
                                .font(.title)
                                .bold()
                                .foregroundColor(myBalance >= 0 ? .green : .red)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }

            Spacer()
        }
        .navigationTitle(group.name)
        .toolbar {
            HStack(spacing: 16) {
                Button(action: { showingAddExpense = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
                Button(action: { showingAddMember = true }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.green)
                }
                Button(action: { showingAllBalances = true }) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            fetchExpenses()
            calculateBalances()
            loadFriends()
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: group) { _ in
                fetchExpenses()
                calculateBalances()
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(group: $group, friends: friends)
        }
        .sheet(isPresented: $showingAllBalances) {
            AllBalancesView(group: group, balances: balances)
        }
    }

    func memberName(for uid: String) -> String {
        group.members.first { $0.id == uid }?.name ?? "未知"
    }

    func fetchExpenses() {
        FirebaseManager.shared.fetchExpenses(for: group.id ?? "") { fetched in
            self.expenses = fetched
        }
    }

    func calculateBalances() {
        guard let groupId = group.id else { return }
        FirebaseManager.shared.calculateBalances(for: groupId) { result in
            self.balances = result
        }
    }

    private func deleteExpense(_ expense: Expense) {
        FirebaseManager.shared.deleteExpense(groupId: group.id ?? "", expense: expense) { error in
            if error == nil {
                self.expenses.removeAll { $0.id == expense.id }
                self.calculateBalances()
            } else {
                print("刪除失敗：\(error!.localizedDescription)")
            }
        }
    }

    private func loadFriends() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUid).collection("friends")
            .getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    friends = docs.map { doc in
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

// 顯示所有成員的分帳結果（額外 sheet）
struct AllBalancesView: View {
    var group: ExpenseGroup
    var balances: [String: Double]

    var body: some View {
        NavigationView {
            List {
                ForEach(group.members, id: \.id) { member in
                    HStack {
                        Text(member.name)
                        Spacer()
                        Text("NT$\(Int(balances[member.id] ?? 0))")
                            .foregroundColor((balances[member.id] ?? 0) >= 0 ? .green : .red)
                    }
                }
            }
            .navigationTitle("所有分帳結果")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
