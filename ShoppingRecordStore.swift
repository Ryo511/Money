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
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidChange), name: .userDidChange, object: nil)
    }
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func fetchRecords() {
        guard let uid = currentUserID else { return }
        
        listener = firebase.database
            .collection("users")
            .document(uid)
            .collection("shoppingRecords")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ 讀取失敗：\(error.localizedDescription)")
                    return
                }
                self.records = snapshot?.documents.compactMap { doc -> ShoppingRecord? in
                    try? doc.data(as: ShoppingRecord.self)
                } ?? []
            }
    }
    
    func addRecord(_ record: ShoppingRecord) {
        guard let uid = currentUserID else { return }
        firebase.addRecord(record, forUser: uid) { error in
            if let error = error {
                print("❌ 新增失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func deleteRecord(_ record: ShoppingRecord) {
        guard let uid = currentUserID else { return }
        firebase.deleteRecord(record, forUser: uid) { error in
            if let error = error {
                print("❌ 刪除失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func records(for date: Date) -> [ShoppingRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    deinit {
        listener?.remove()
    }
    
    @objc func userDidChange() {
        // 移除舊 listener
        listener?.remove()
        records = [] // 清空舊資料
        
        // 重新抓資料
        fetchRecords()
    }
}
