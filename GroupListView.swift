//
//  GroupView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/31.
//

import SwiftUI

struct GroupListView: View {
    @State private var groups: [ExpenseGroup] = []
    @State private var showingAddGroup = false
    @State private var showingAddFriend = false

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(groups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                Text("\(group.members.count) 位成員")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteGroup)
                }
                .navigationTitle("群組")
                .toolbar {
                    // 右上角 person icon -> AddFriendView
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddFriend = true }) {
                            Image(systemName: "person")
                        }
                    }
                }
                
                // 右下角浮動圓形 + -> AddGroupView
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddGroup = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            // AddGroupView Sheet
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView { newGroup in
                    FirebaseManager.shared.createGroup(newGroup) { _ in
                        fetchGroups()
                    }
                }
            }
            // AddFriendView Sheet
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .onAppear {
                fetchGroups()
            }
        }
    }

    // 取得群組列表
    func fetchGroups() {
        FirebaseManager.shared.fetchGroups { fetched in
            self.groups = fetched
        }
    }

    // 刪除群組
    func deleteGroup(at offsets: IndexSet) {
        offsets.forEach { index in
            let group = groups[index]
            FirebaseManager.shared.deleteGroup(group) { error in
                if let error = error {
                    print("刪除群組失敗: \(error.localizedDescription)")
                } else {
                    print("刪除群組成功")
                }
            }
        }
        groups.remove(atOffsets: offsets)
    }
}
