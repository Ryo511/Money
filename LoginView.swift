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
