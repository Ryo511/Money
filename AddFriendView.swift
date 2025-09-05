//
//  AddFriendView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/09/01.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddFriendView: View {
    @State private var searchText = ""
    @State private var searchResults: [AppUser] = []
    @State private var friends: [AppUser] = []
    @State private var sentRequests: Set<String> = []
    @State private var friendRequests: [FriendRequest] = []
    @State private var showRequests = false

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("搜尋朋友名稱或 Email", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: { searchUsers(keyword: searchText) }) {
                        Text("搜尋")
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    // 🔔 通知鈴鐺
                    Button(action: { showRequests.toggle() }) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            if !friendRequests.isEmpty {
                                Text("\(friendRequests.count)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                }
                .padding()

                List {
                    // 搜尋結果
                    if !searchResults.isEmpty {
                        Section("搜尋結果") {
                            ForEach(searchResults) { user in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(user.name)
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: { sendFriendRequest(to: user) }) {
                                        Text(sentRequests.contains(user.id ?? "") ? "已邀請" : "加為好友")
                                            .foregroundColor(sentRequests.contains(user.id ?? "") ? .gray : .blue)
                                    }
                                    .disabled(sentRequests.contains(user.id ?? ""))
                                }
                            }
                        }
                    }

                    // 我的好友
                    Section("我的好友") {
                        ForEach(friends) { friend in
                            VStack(alignment: .leading) {
                                Text(friend.name)
                                Text(friend.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("好友")
            .sheet(isPresented: $showRequests) {
                FriendRequestsView(friendRequests: $friendRequests, friends: $friends)
            }
            .onAppear {
                loadFriends()
                loadFriendRequests()
            }
        }
    }

    // MARK: - 搜尋使用者
    func searchUsers(keyword: String) {
        guard !keyword.isEmpty else { searchResults = []; return }
        let db = Firestore.firestore()
        // name 搜尋
        db.collection("users")
            .whereField("name", isGreaterThanOrEqualTo: keyword)
            .whereField("name", isLessThanOrEqualTo: keyword + "\u{f8ff}")
            .getDocuments { snapshot, error in
                var nameResults: [AppUser] = []
                if let docs = snapshot?.documents {
                    nameResults = docs.map { doc in
                        AppUser(id: doc.documentID,
                                name: doc["name"] as? String ?? "",
                                email: doc["email"] as? String ?? "")
                    }
                }
                // email 搜尋
                db.collection("users")
                    .whereField("email", isGreaterThanOrEqualTo: keyword)
                    .whereField("email", isLessThanOrEqualTo: keyword + "\u{f8ff}")
                    .getDocuments { snapshot2, error2 in
                        var emailResults: [AppUser] = []
                        if let docs2 = snapshot2?.documents {
                            emailResults = docs2.map { doc in
                                AppUser(id: doc.documentID,
                                        name: doc["name"] as? String ?? "",
                                        email: doc["email"] as? String ?? "")
                            }
                        }
                        // 合併去重
                        let combined = (nameResults + emailResults).reduce(into: [String: AppUser]()) { dict, user in
                            if let id = user.id { dict[id] = user }
                        }
                        searchResults = Array(combined.values)
                    }
            }
    }

    // MARK: - 發送好友邀請
    func sendFriendRequest(to user: AppUser) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let userId = user.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("friendRequests")
            .document(currentUid)
            .setData(["from": currentUid, "date": Timestamp()]) { error in
                if let error = error { print("❌ 發送好友邀請失敗: \(error.localizedDescription)") }
                else { sentRequests.insert(userId); print("✅ 好友邀請已發送給 \(user.name)") }
            }
    }

    // MARK: - 讀取好友列表
    func loadFriends() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUid).collection("friends")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    friends = docs.map { doc in
                        AppUser(id: doc.documentID,
                                name: doc["name"] as? String ?? "",
                                email: doc["email"] as? String ?? "")
                    }
                }
            }
    }

    // MARK: - 讀取好友邀請
    func loadFriendRequests() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUid).collection("friendRequests")
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    friendRequests = docs.map { doc in
                        FriendRequest(id: doc.documentID,
                                      fromUid: doc["from"] as? String ?? "")
                    }
                }
            }
    }
}

// MARK: - AppUser Model
struct AppUser: Identifiable, Codable {
    var id: String?
    var name: String
    var email: String
}

// MARK: - FriendRequest Model
struct FriendRequest: Identifiable {
    var id: String?
    var fromUid: String
}

// MARK: - 好友邀請列表
struct FriendRequestsView: View {
    @Binding var friendRequests: [FriendRequest]
    @Binding var friends: [AppUser]

    var body: some View {
        NavigationView {
            List {
                ForEach(friendRequests) { request in
                    FriendRequestRow(request: request,
                                     onAccept: { acceptFriendRequest(request) })
                }
            }
            .navigationTitle("好友邀請")
        }
    }

    // 單筆好友邀請 UI
    struct FriendRequestRow: View {
        let request: FriendRequest
        let onAccept: () -> Void
        @State private var requester: AppUser?

        var body: some View {
            HStack {
                if let requester = requester {
                    VStack(alignment: .leading) {
                        Text(requester.name).font(.headline)
                        Text(requester.email).font(.caption).foregroundColor(.gray)
                    }
                } else {
                    Text("載入中…")
                }
                Spacer()
                Button("接受") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
            }
            .onAppear {
                loadRequester()
            }
        }

        func loadRequester() {
            let db = Firestore.firestore()
            db.collection("users").document(request.fromUid).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    requester = AppUser(id: snapshot?.documentID,
                                        name: data["name"] as? String ?? "",
                                        email: data["email"] as? String ?? "")
                }
            }
        }
    }

    func acceptFriendRequest(_ request: FriendRequest) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        // 1️⃣ 取得對方資料
        db.collection("users").document(request.fromUid).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            let friend = AppUser(id: snapshot?.documentID,
                                 name: data["name"] as? String ?? "",
                                 email: data["email"] as? String ?? "")

            // 2️⃣ 將對方加入自己的好友
            db.collection("users").document(currentUid).collection("friends")
                .document(friend.id!).setData([
                    "name": friend.name,
                    "email": friend.email
                ])

            // 3️⃣ 將自己加入對方好友
            if let selfUser = Auth.auth().currentUser {
                db.collection("users").document(friend.id!).collection("friends")
                    .document(selfUser.uid).setData([
                        "name": selfUser.displayName ?? "",
                        "email": selfUser.email ?? ""
                    ])
            }

            // 4️⃣ 刪除好友邀請
            db.collection("users").document(currentUid).collection("friendRequests")
                .document(request.id!).delete()

            // 5️⃣ 更新本地列表
            friends.append(friend)
            friendRequests.removeAll { $0.id == request.id }
        }
    }
}
