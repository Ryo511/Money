//
//  LoginView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false

    var body: some View {
        VStack(spacing: 20) {
            Text(isRegistering ? "註冊帳號" : "登入")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("密碼", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Button(action: {
                if isRegistering {
                    authViewModel.register(email: email, password: password)
                } else {
                    authViewModel.login(email: email, password: password)
                }
            }) {
                Text(isRegistering ? "註冊" : "登入")
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
                Text(isRegistering ? "已有帳號？請登入" : "沒有帳號？註冊")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            
            if let user = authViewModel.user {
                Text("👤 \(user.displayName ?? "使用者")")
                Text("📧 \(user.email ?? "")")
            }
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newName = ""

    var body: some View {
        Form {
            Section {
                TextField("暱稱", text: $newName)
                Button("更新名稱") {
                    if let user = Auth.auth().currentUser {
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = newName
                        changeRequest.commitChanges { error in
                            if let error = error {
                                print("更新失敗：\(error.localizedDescription)")
                            } else {
                                authViewModel.user = Auth.auth().currentUser
                            }
                        }
                    }
                }
            } header: {
                Text("個人資訊")
            }

            Section {
                Button("登出") {
                    authViewModel.logout()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("設定")
        .onAppear {
            newName = Auth.auth().currentUser?.displayName ?? ""
        }
    }
}

struct AppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.user != nil {
                ContentView() // ✅ 這是你 app 的主頁面，登入後會看到
            } else {
                LoginView()
            }
        }
        .onAppear {
            authViewModel.listenToAuthState() // 確保 user 狀態及時更新
        }
    }
}

#Preview {
    LoginView()
}
