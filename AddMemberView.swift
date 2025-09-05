//
//  AddMemberView.swift
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddMemberView: View {
    @Binding var group: ExpenseGroup
    var friends: [AppUser] // 你的好友列表 (從 GroupDetailView 傳入)
    @Environment(\.dismiss) var dismiss

    @State private var alertMessage: String = ""
    @State private var showingAlert: Bool = false
    @State private var isProcessing: Bool = false

    var body: some View {
        NavigationView {
            List {
                ForEach(friends) { friend in
                    Button {
                        tryAddFriend(friend)
                    } label: {
                        HStack {
                            Text(friend.name)
                            Spacer()
                            if group.members.contains(where: { $0.id == friend.id }) {
                                Text("已在群組")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    .disabled(isProcessing || group.members.contains(where: { $0.id == friend.id }))
                }
            }
            .navigationTitle("新增群組好友")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertMessage))
            }
        }
    }

    func tryAddFriend(_ friend: AppUser) {
        guard let currentUid = Auth.auth().currentUser?.uid,
              let friendId = friend.id else { return }

        isProcessing = true
        let db = Firestore.firestore()
        db.collection("users").document(currentUid).collection("friends").document(friendId)
            .getDocument { snapshot, error in
                isProcessing = false
                if let error = error {
                    alertMessage = "檢查好友關係時發生錯誤：\(error.localizedDescription)"
                    showingAlert = true
                    return
                }

                if snapshot?.exists == true {
                    // 你的好友，可以加入群組
                    // 避免重複加入
                    if !group.members.contains(where: { $0.id == friendId }) {
                        var updatedMembers = group.members
                        updatedMembers.append(Member(id: friendId, name: friend.name))
                        group.members = updatedMembers

                        // 更新 Firestore 上的群組成員
                        FirebaseManager.shared.updateGroupMembers(group: group) { error in
                            if let error = error {
                                alertMessage = "更新群組失敗：\(error.localizedDescription)"
                                showingAlert = true
                            } else {
                                // 成功後關閉 modal
                                dismiss()
                            }
                        }
                    } else {
                        alertMessage = "該成員已在群組中"
                        showingAlert = true
                    }
                } else {
                    // 不是你的好友
                    alertMessage = "只能加入你的好友"
                    showingAlert = true
                }
            }
    }
}
