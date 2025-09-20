//
//  AuthViewModel.swift
//  Money
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User? {
            didSet {
                // 當使用者變動時，發出通知
                NotificationCenter.default.post(name: .userDidChange, object: user)
            }
        }
    @Published var errorMessage = ""

    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }
    }

    // =======================
    // MARK: - 註冊帳號
    // =======================
    func register(email: String, password: String, displayName: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            guard let self = self, let user = result?.user else { return }
            self.user = user

            // 更新 Firebase Auth 使用者的 displayName
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("更新 displayName 失敗：\(error.localizedDescription)")
                }
            }

            // 建立 Firestore users document
            self.createFirestoreUserIfNotExists(for: user, displayName: displayName, email: email)
        }
    }

    // =======================
    // MARK: - 登入
    // =======================
    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            guard let self = self, let user = result?.user else { return }
            self.user = user

            // 登入後檢查 Firestore users document 是否存在
            self.createFirestoreUserIfNotExists(for: user, displayName: user.displayName ?? "", email: user.email ?? "")
        }
    }

    // =======================
    // MARK: - 登出
    // =======================
    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("登出失敗: \(error.localizedDescription)")
        }
    }

    // =======================
    // MARK: - 監聽 Auth 狀態
    // =======================
    func listenToAuthState() {
        // 防止重複註冊監聽
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateHandle = nil
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    // =======================
    // MARK: - Firestore User 建立 / 補資料
    // =======================
    private func createFirestoreUserIfNotExists(for user: User, displayName: String, email: String) {
        let docRef = db.collection("users").document(user.uid)

        docRef.getDocument { snapshot, error in
            if let error = error {
                print("檢查 Firestore users document 失敗：\(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot, snapshot.exists {
                // 已經有資料，不做事
                print("Firestore users document 已存在 ✅")
            } else {
                // 沒有資料，補上
                let userData: [String: Any] = [
                    "id": user.uid,
                    "name": displayName,
                    "email": email,
                    "createdAt": Timestamp()
                ]
                docRef.setData(userData) { err in
                    if let err = err {
                        print("Firestore users document 補資料失敗：\(err.localizedDescription)")
                    } else {
                        print("Firestore users document 已補上 ✅")
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let userDidChange = Notification.Name("userDidChange")
}
