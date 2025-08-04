//
//  LoginMainView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//

import SwiftUI
import FirebaseAuth

struct LoginMainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("帳戶資訊")) {
                    Text("📧 Email: \(authViewModel.user?.email ?? "未知")")
                    
                    TextField("輸入暱稱", text: $newName)
                    
                    Button("更新暱稱") {
                        updateDisplayName()
                    }
                }
                
                Section(header: Text("帳戶安全")) {
                    Button("更改密碼") {
                        resetPassword()
                    }
                }
                
                Section {
                    Button("登出") {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("個人資料")
            .onAppear {
                newName = authViewModel.user?.displayName ?? ""
            }
        }
    }
    
    func updateDisplayName() {
        guard let user = Auth.auth().currentUser else { return }
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

    func resetPassword() {
        guard let email = authViewModel.user?.email else { return }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("重設密碼錯誤：\(error.localizedDescription)")
            } else {
                print("已寄送密碼重設連結至：\(email)")
            }
        }
    }
}

#Preview {
    LoginMainView()
}
