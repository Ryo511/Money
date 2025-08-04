//
//  AuthViewModel.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//

import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
            self.isLoggedIn = user != nil
        }
    }

    func register(email: String, password: String, name: String? = nil) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            if let name = name, !name.isEmpty {
                let changeRequest = result?.user.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges(completion: nil)
            }
        }
    }

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func logout() {
        try? Auth.auth().signOut()
    }
    
    func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }
}
