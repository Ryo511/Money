//
//  LoginView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - 登入 / 註冊畫面
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = "" // 新增暱稱欄位
    @State private var isRegistering = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isRegistering ? NSLocalizedString("RegisterAccount", comment: "註冊帳號") : NSLocalizedString("Login", comment: "登入"))
                .font(.largeTitle)
                .bold()
            
            TextField(NSLocalizedString("Email", comment: "Email"), text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            SecureField(NSLocalizedString("Password", comment: "密碼"), text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            
            // 註冊模式才顯示暱稱欄位
            if isRegistering {
                TextField(NSLocalizedString("Nickname", comment: "暱稱"), text: $displayName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            Button(action: {
                if isRegistering {
                    authViewModel.register(email: email, password: password, displayName: displayName) //傳入暱稱
                } else {
                    authViewModel.login(email: email, password: password)
                }
            }) {
                Text(isRegistering ? NSLocalizedString("Register", comment: "註冊") : NSLocalizedString("Login", comment: "登入"))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            if !authViewModel.errorMessage.isEmpty {
                Text(authViewModel.errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top)
            }
            
            Button(action: {
                isRegistering.toggle()
            }) {
                Text(isRegistering ? NSLocalizedString("AlreadyAccount", comment: "已有帳號？請登入") : NSLocalizedString("NoAccount", comment: "沒有帳號？註冊"))
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            
            if let user = authViewModel.user {
                Text("👤 \(user.displayName ?? NSLocalizedString("User", comment: "使用者"))")
                Text("📧 \(user.email ?? "")")
            }
        }
        .padding()
    }
}

// MARK: - 設定頁面 (個人資訊 + 修改暱稱 + 登出)
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newName = ""
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    var body: some View {
        Form {
            // 個人資訊
            Section(header: Text(NSLocalizedString("PersonalInfo", comment: "個人資訊"))) {
                if let user = Auth.auth().currentUser {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(user.displayName ?? NSLocalizedString("User", comment: "使用者"))
                                    .font(.headline)
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("🆔 UID")
                            Spacer()
                            Text(user.uid)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        if let created = user.metadata.creationDate {
                            HStack {
                                Text("📅 \(NSLocalizedString("CreatedAt", comment: "建立時間"))")
                                Spacer()
                                Text(Self.dateFormatter.string(from: created))
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                    }
                } else {
                    Text(NSLocalizedString("NoUserInfo", comment: "無使用者資訊"))
                        .foregroundColor(.secondary)
                }
            }
            
            // 修改暱稱
            Section(header: Text(NSLocalizedString("EditInfo", comment: "編輯資料"))) {
                TextField(NSLocalizedString("Nickname", comment: "暱稱"), text: $newName)
                
                Button(NSLocalizedString("UpdateName", comment: "更新名稱")) {
                    guard let user = Auth.auth().currentUser else { return }
                    
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = newName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("更新失敗：\(error.localizedDescription)")
                            return
                        }
                        
                        // 刷新 user
                        DispatchQueue.main.async {
                            authViewModel.user = Auth.auth().currentUser
                        }
                        
                        let db = Firestore.firestore()
                        
                        // 更新 users collection
                        db.collection("users").document(user.uid).setData([
                            "name": newName,
                            "email": user.email ?? ""
                        ], merge: true)
                        
                        // 更新 groups collection
                        db.collection("groups").getDocuments { snapshot, error in
                            guard let documents = snapshot?.documents else { return }
                            
                            for doc in documents {
                                do {
                                    // 先 decode 成 ExpenseGroup
                                    var group = try doc.data(as: ExpenseGroup.self)
                                    // 找到 uid 對應的 member 改名字
                                    if let index = group.members.firstIndex(where: { $0.id == user.uid }) {
                                        group.members[index].name = newName
                                    }
                                    // 再用 FirebaseManager 直接覆寫
                                    FirebaseManager.shared.updateGroupMembers(group: group)
                                } catch {
                                    print("解析群組失敗: \(error)")
                                }
                            }
                        }
                    }
                }
            }
            
            // 登出
            Section {
                Button(NSLocalizedString("Logout", comment: "登出")) {
                    authViewModel.logout()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle(NSLocalizedString("Settings", comment: "設定"))
        .onAppear {
            newName = Auth.auth().currentUser?.displayName ?? ""
        }
    }
}

// MARK: - App Root View
struct AppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.user != nil {
                ContentView() // 登入後的主頁面
            } else {
                LoginView()
            }
        }
        .onAppear {
            authViewModel.listenToAuthState()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
