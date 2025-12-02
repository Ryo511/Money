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
    @StateObject private var viewModel: GroupDetailViewModel

    @State private var showingAddExpense = false
    @State private var showingAddMember = false
    @State private var showingAllBalances = false

    // creat init -> group -> ViewModel
    init(group: ExpenseGroup) {
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }

    var body: some View {
        VStack {
            // 成員列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.group.members) { member in
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
                ForEach(viewModel.expenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title)
                                .bold()
                            Text("付款者: \(viewModel.memberName(for: expense.paidBy))")
                                .font(.caption)
                        }
                        Spacer()
                        Text("NT$\(Int(expense.amount))")
                            .bold()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteExpense(expense)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    }
                }
            }

            Divider()

            // 只顯示「我的應付/應收」摘要卡片
            if let myBalance = viewModel.myBalance {
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
        .navigationTitle(viewModel.group.name)
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
        .onDisappear {
            viewModel.stopListening()
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: viewModel.group) { _ in
                // 這裡不需要手動 fetch，因為 listener 會自動更新
            }
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(group: $viewModel.group, friends: viewModel.friends)
        }
        .sheet(isPresented: $showingAllBalances) {
            AllBalancesView(group: viewModel.group, balances: viewModel.balances)
        }
    }
}

// 顯示所有成員的分帳結果（這段可以沿用你原本的）
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
