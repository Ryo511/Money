//
//  ShoppingRecordStore.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ShoppingRecordStore: ObservableObject {
    @Published var records: [ShoppingRecord] = []
    
    private let firebase = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidChange), name: .userDidChange, object: nil)
        fetchRecords()
    }
    
    func fetchRecords() {
        guard let uid = currentUserID else { return }
        // 先移除舊 listener
        listener?.remove()
        listener = firebase.listenRecords(forUser: uid) { [weak self] fetched in
            self?.records = fetched
        }
    }
    
    func addRecord(_ record: ShoppingRecord) {
        guard let uid = currentUserID else { return }
        firebase.addRecord(record, forUser: uid) { error in
            if let error = error {
                print("新增失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func deleteRecord(_ record: ShoppingRecord) {
        guard let uid = currentUserID else { return }
        firebase.deleteRecord(record, forUser: uid) { error in
            if let error = error {
                print("刪除失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func records(for date: Date) -> [ShoppingRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    @objc func userDidChange() {
        // 使用者變動時重新抓資料
        fetchRecords()
    }
    
    deinit {
        listener?.remove()
    }
}
