//
//  ShoppingRecordStore.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import Foundation
import FirebaseFirestore
import Combine

class ShoppingRecordStore: ObservableObject {
    @Published var records: [ShoppingRecord] = []
    private let db = Firestore.firestore()
    
    init() {
        fetchRecords()
    }
    
    func fetchRecords() {
        db.collection("shoppingRecords")
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
    
    func addRecord(_ record: ShoppingRecord, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("shoppingRecords").addDocument(from: record, completion: completion)
        } catch {
            completion?(error)
        }
    }
    
    func delete(_ record: ShoppingRecord) {
        guard let id = record.id else { return }
        db.collection("shoppingRecords").document(id).delete { error in
            if let error = error {
                print("❌ 刪除失敗：\(error.localizedDescription)")
            }
        }
    }
    
    func records(for date: Date) -> [ShoppingRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
