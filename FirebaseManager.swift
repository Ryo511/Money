//
//  FirebaseManager.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//

import FirebaseFirestore
import FirebaseAuth

// =======================
// MARK: - 單人支出
// =======================
struct ShoppingRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var date: Date
    var category: String
    var amount: Double
    var location: String
}

// =======================
// MARK: - 群組分帳資料結構
// =======================
struct Member: Codable, Identifiable {
    var id: String   // Firebase uid
    var name: String
}

struct ExpenseGroup: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var members: [Member]
}

struct Expense: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var amount: Double
    var paidBy: String   // uid
    var splitMethod: String // "equal" or "custom"
    var customSplit: [String: Double]? // uid : ratio
    var date: Date
}

// =======================
// MARK: - Firebase Manager
// =======================
class FirebaseManager {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    
    private init() {}
    
    // =======================
    // 單人支出
    // =======================
    func addRecord(_ record: ShoppingRecord, forUser uid: String, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("users")
                .document(uid)
                .collection("shoppingRecords")
                .addDocument(from: record, completion: completion)
        } catch {
            completion?(error)
        }
    }
    
    func fetchRecords(forUser uid: String, completion: @escaping ([ShoppingRecord]) -> Void) {
        db.collection("users")
            .document(uid)
            .collection("shoppingRecords")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, _ in
                let records = snapshot?.documents.compactMap { try? $0.data(as: ShoppingRecord.self) } ?? []
                completion(records)
            }
    }
    
    func deleteRecord(_ record: ShoppingRecord, forUser uid: String, completion: ((Error?) -> Void)? = nil) {
        guard let recordId = record.id else {
            completion?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Record id is missing"]))
            return
        }
        db.collection("users").document(uid).collection("shoppingRecords").document(recordId).delete(completion: completion)
    }
    
    // =======================
    // 群組
    // =======================
    
    // 創建群組
    func createGroup(_ group: ExpenseGroup, forUser creatorUid: String, completion: ((Error?) -> Void)? = nil) {
        let groupData: [String: Any] = [
            "name": group.name,
            "members": group.members.map { ["id": $0.id, "name": $0.name] }
        ]
        
        let groupRef = db.collection("users").document(creatorUid).collection("groups").document()
        groupRef.setData(groupData) { error in
            if let error = error {
                completion?(error)
                return
            }
            
            // 複製群組到其他成員
            for member in group.members where member.id != creatorUid {
                let memberRef = self.db.collection("users").document(member.id).collection("groups").document(groupRef.documentID)
                memberRef.setData(groupData) { setError in
                    if let setError = setError {
                        completion?(setError)
                        return
                    }
                }
            }
            completion?(nil)
        }
    }
    
    // 監聽群組
    func listenGroups(forUser uid: String, completion: @escaping ([ExpenseGroup]) -> Void) {
        db.collection("users")
            .document(uid)
            .collection("groups")
            .addSnapshotListener { snapshot, _ in
                let groups = snapshot?.documents.compactMap { try? $0.data(as: ExpenseGroup.self) } ?? []
                completion(groups)
            }
    }
    
    // 刪除群組
    func deleteGroup(_ group: ExpenseGroup, forUser uid: String, completion: ((Error?) -> Void)? = nil) {
        guard let groupId = group.id else {
            completion?(NSError(domain: "MissingGroupID", code: 0, userInfo: nil))
            return
        }

        let groupRef = db.collection("users").document(uid).collection("groups").document(groupId)
        
        groupRef.collection("expenses").getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
            groupRef.delete(completion: completion)
        }
    }
    
    // 更新群組成員
    func updateGroupMembers(group: ExpenseGroup, completion: ((Error?) -> Void)? = nil) {
        guard let groupId = group.id else {
            completion?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group id is missing"]))
            return
        }

        let groupData: [String: Any] = [
            "name": group.name,
            "members": group.members.map { ["id": $0.id, "name": $0.name] }
        ]

        for member in group.members {
            let memberGroupRef = db.collection("users").document(member.id).collection("groups").document(groupId)
            memberGroupRef.setData(groupData, merge: true) { error in
                if let error = error {
                    print("更新群組 \(group.name) 成員失敗: \(error.localizedDescription)")
                    completion?(error)
                    return
                }
            }
        }
        completion?(nil)
    }
    
    // =======================
    // 群組支出方法
    // =======================
    
    func fetchExpenses(for groupId: String, completion: @escaping ([Expense]) -> Void) {
        db.collection("groups").document(groupId).collection("expenses")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 讀取群組支出失敗：\(error.localizedDescription)")
                    completion([])
                    return
                }

                let expenses = snapshot?.documents.compactMap { try? $0.data(as: Expense.self) } ?? []
                completion(expenses)
            }
    }
    
    func calculateBalances(for groupId: String, completion: @escaping ([String: Double]) -> Void) {
        fetchExpenses(for: groupId) { expenses in
            var totalSpentByUser: [String: Double] = [:] // 每個人的總支出
            var balances: [String: Double] = [:]

            // 先把每個人的支出累加
            for expense in expenses {
                totalSpentByUser[expense.paidBy, default: 0] += expense.amount
            }

            // 取得群組成員數量
            FirebaseManager.shared.listenGroups(forUser: Auth.auth().currentUser?.uid ?? "") { groups in
                guard let group = groups.first(where: { $0.id == groupId }) else {
                    completion([:])
                    return
                }

                let memberCount = group.members.count
                guard memberCount > 0 else {
                    completion([:])
                    return
                }

                // 計算總支出
                let totalGroupSpent = totalSpentByUser.values.reduce(0, +)
                let averageSpent = totalGroupSpent / Double(memberCount)

                // 計算每個人的應付/應收
                for member in group.members {
                    let spent = totalSpentByUser[member.id] ?? 0
                    balances[member.id] = spent - averageSpent
                }

                completion(balances)
            }
        }
    }
    
    func deleteExpense(groupId: String, expense: Expense, completion: ((Error?) -> Void)? = nil) {
        guard let expenseId = expense.id else {
            completion?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expense id is missing"]))
            return
        }

        let expenseRef = db.collection("groups").document(groupId).collection("expenses").document(expenseId)
        expenseRef.delete { error in
            if let error = error {
                print("❌ 刪除群組支出失敗：\(error.localizedDescription)")
            }
            completion?(error)
        }
    }
    
    func listenRecords(forUser uid: String, completion: @escaping ([ShoppingRecord]) -> Void) -> ListenerRegistration {
        return db.collection("users")
            .document(uid)
            .collection("shoppingRecords")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ 讀取失敗：\(error.localizedDescription)")
                    completion([])
                    return
                }
                let records = snapshot?.documents.compactMap { try? $0.data(as: ShoppingRecord.self) } ?? []
                completion(records)
            }
    }
    
    // =======================
    // 新增群組支出
    // =======================
    func addExpense(to groupId: String, expense: Expense, completion: @escaping (Error?) -> Void) {
        guard !groupId.isEmpty else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group ID is empty"]))
            return
        }

        let expenseData: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "paidBy": expense.paidBy,
            "splitMethod": expense.splitMethod,
            "customSplit": expense.customSplit ?? [:],
            "date": Timestamp(date: expense.date)
        ]

        db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .addDocument(data: expenseData) { error in
                completion(error)
            }
    }
    
    func listenExpenses(for groupId: String, completion: @escaping ([Expense]) -> Void) -> ListenerRegistration {
        return db.collection("groups")
            .document(groupId)
            .collection("expenses")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ 讀取群組支出失敗：\(error.localizedDescription)")
                    completion([])
                    return
                }
                let expenses = snapshot?.documents.compactMap { try? $0.data(as: Expense.self) } ?? []
                completion(expenses)
            }
    }
}
