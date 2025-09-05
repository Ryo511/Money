//
//  AddGroupView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/31.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    
    // 好友列表從 Firebase 讀取
    @State private var friends: [AppUser] = []
    
    // 已選擇的好友
    @State private var selectedMembers = Set<String>() // 存好友 id
    
    var onSave: (ExpenseGroup) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                // 群組名稱
                TextField("輸入群組名稱", text: $groupName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // 已選好友圓圈
                if !selectedMembers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 10) {
                            ForEach(friends.filter { selectedMembers.contains($0.id ?? "") }) { friend in
                                Button(action: {
                                    // 點擊移除好友
                                    if let id = friend.id {
                                        selectedMembers.remove(id)
                                    }
                                }) {
                                    Text(friend.name.prefix(2)) // 顯示名字前兩個字
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50) // 控制圓圈高度
                }
                
                Text("選擇成員")
                    .font(.headline)
                    .padding(.horizontal)
                
                // 好友列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(friends) { friend in
                            Button(action: {
                                if let id = friend.id {
                                    if selectedMembers.contains(id) {
                                        selectedMembers.remove(id)
                                    } else {
                                        selectedMembers.insert(id)
                                    }
                                }
                            }) {
                                HStack {
                                    Text(friend.name)
                                    Spacer()
                                    if let id = friend.id, selectedMembers.contains(id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                            }
                            Divider() // 模擬 List 分隔線
                        }
                    }
                }
            }
            .navigationTitle("新增群組")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        var members = friends.compactMap { friend -> Member? in
                            if let id = friend.id, selectedMembers.contains(id) {
                                return Member(id: id, name: friend.name)
                            }
                            return nil
                        }

                        // 加上自己
                        if let currentUser = Auth.auth().currentUser {
                            let selfMember = Member(id: currentUser.uid, name: currentUser.displayName ?? "我自己")
                            if !members.contains(where: { $0.id == selfMember.id }) {
                                members.append(selfMember)
                            }
                        }

                        let group = ExpenseGroup(name: groupName, members: members)
                        onSave(group)
                        dismiss()
                    }
                    .disabled(groupName.isEmpty || selectedMembers.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                loadFriends()
            }
        }
    }
    
    // MARK: - 從 Firebase 讀取好友
    func loadFriends() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUid).collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 讀取好友失敗: \(error.localizedDescription)")
                    return
                }
                
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
