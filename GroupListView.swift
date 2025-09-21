//
//  GroupView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/31.
//

import SwiftUI
import FirebaseAuth

struct GroupListView: View {
    @State private var groups: [ExpenseGroup] = []
    @State private var showingAddGroup = false
    @State private var showingAddFriend = false
    
    var currentUserUid: String? {
        Auth.auth().currentUser?.uid
    }

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
                if let uid = currentUserUid {
                    AddGroupView { newGroup in
                        FirebaseManager.shared.createGroup(newGroup, forUser: uid) { _ in
                            // UI 自動更新，無需手動 fetch
                        }
                    }
                } else {
                    Text("使用者未登入")
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
        guard let uid = currentUserUid else { return }
        FirebaseManager.shared.listenGroups(forUser: uid) { fetched in
            self.groups = fetched
        }
    }

    // 刪除群組
    func deleteGroup(at offsets: IndexSet) {
        guard let uid = currentUserUid else { return }
        offsets.forEach { index in
            let group = groups[index]
            FirebaseManager.shared.deleteGroup(group, forUser: uid)
        }
        groups.remove(atOffsets: offsets)
    }
}
