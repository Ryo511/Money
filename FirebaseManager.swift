//
//  FirebaseManager.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//

import FirebaseFirestore

struct ShoppingRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var date: Date
    var category: String
    var amount: Double
    var location: String
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    func addRecord(_ record: ShoppingRecord, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("shoppingRecords").addDocument(from: record, completion: completion)
        } catch {
            completion?(error)
        }
    }
    
    func fetchAllRecords(completion: @escaping ([ShoppingRecord]) -> Void) {
        db.collection("shoppingRecords").order(by: "date", descending: true).getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let records = documents.compactMap {
                    try? $0.data(as: ShoppingRecord.self)
                }
                completion(records)
            } else {
                completion([])
            }
        }
    }
    
    func deleteRecord(_ record: ShoppingRecord, completion: ((Error?) -> Void)? = nil) {
        guard let id = record.id else {
            completion?(NSError(domain: "MissingID", code: 0, userInfo: nil))
            return
        }
        db.collection("shoppingRecords").document(id).delete(completion: completion)
    }
}
