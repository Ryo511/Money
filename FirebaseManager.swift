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
    private let db = Firestore.firestore()
    var database: Firestore {
        return db
    }
    
    private init() {}
    
    // MARK: - 單人支出 (依 uid 區分)
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
            .addSnapshotListener { snapshot, error in
                if let documents = snapshot?.documents {
                    let records = documents.compactMap { try? $0.data(as: ShoppingRecord.self) }
                    completion(records)
                } else {
                    completion([])
                }
            }
    }
    
    func deleteRecord(_ record: ShoppingRecord, forUser uid: String, completion: ((Error?) -> Void)? = nil) {
        guard let id = record.id else {
            completion?(NSError(domain: "MissingID", code: 0, userInfo: nil))
            return
        }
        db.collection("users")
            .document(uid)
            .collection("shoppingRecords")
            .document(id)
            .delete(completion: completion)
    }
    
    // MARK: - 群組 & 分帳紀錄（保持原本功能不變）
    func createGroup(_ group: ExpenseGroup, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("groups").addDocument(from: group, completion: completion)
        } catch {
            completion?(error)
        }
    }
    
    func updateGroupMembers(group: ExpenseGroup, completion: ((Error?) -> Void)? = nil) {
        guard let groupId = group.id else {
            completion?(NSError(domain: "MissingGroupID", code: 0, userInfo: [NSLocalizedDescriptionKey: "Group id is missing"]))
            return
        }
        let membersData = group.members.map { ["id": $0.id, "name": $0.name] }
        db.collection("groups").document(groupId).setData([
            "name": group.name,
            "members": membersData
        ], merge: true, completion: completion)
    }
    
    func fetchGroups(completion: @escaping ([ExpenseGroup]) -> Void) {
        db.collection("groups").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let groups = documents.compactMap { try? $0.data(as: ExpenseGroup.self) }
                completion(groups)
            } else {
                completion([])
            }
        }
    }
    
    func addExpense(to groupId: String, expense: Expense, completion: ((Error?) -> Void)? = nil) {
        do {
            _ = try db.collection("groups").document(groupId).collection("expenses").addDocument(from: expense, completion: completion)
        } catch {
            completion?(error)
        }
    }
    
    func fetchExpenses(for groupId: String, completion: @escaping ([Expense]) -> Void) {
        db.collection("groups").document(groupId).collection("expenses")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let expenses = documents.compactMap { try? $0.data(as: Expense.self) }
                    completion(expenses)
                } else {
                    completion([])
                }
            }
    }
    
    func deleteExpense(groupId: String, expense: Expense, completion: ((Error?) -> Void)? = nil) {
        guard let id = expense.id else {
            completion?(NSError(domain: "MissingID", code: 0, userInfo: nil))
            return
        }
        db.collection("groups").document(groupId).collection("expenses").document(id).delete(completion: completion)
    }
    
    // MARK: - 分帳計算
    func calculateBalances(for groupId: String, completion: @escaping ([String: Double]) -> Void) {
        let groupRef = db.collection("groups").document(groupId)
        
        groupRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let membersData = data["members"] as? [[String: Any]] else {
                completion([:])
                return
            }
            
            let memberIds = membersData.compactMap { $0["id"] as? String }
            var balances = Dictionary(uniqueKeysWithValues: memberIds.map { ($0, 0.0) })
            
            groupRef.collection("expenses").getDocuments { expSnapshot, error in
                guard let docs = expSnapshot?.documents else {
                    completion(balances)
                    return
                }
                
                for doc in docs {
                    if let expense = try? doc.data(as: Expense.self) {
                        switch expense.splitMethod {
                        case "equal":
                            let share = expense.amount / Double(memberIds.count)
                            balances[expense.paidBy, default: 0] += expense.amount
                            for memberId in memberIds {
                                balances[memberId, default: 0] -= share
                            }
                        case "custom":
                            if let splits = expense.customSplit {
                                balances[expense.paidBy, default: 0] += expense.amount
                                for (memberId, share) in splits {
                                    balances[memberId, default: 0] -= share
                                }
                            }
                        default:
                            break
                        }
                    }
                }
                
                completion(balances)
            }
        }
    }
    
    func calculateDetailedBalances(for groupId: String, completion: @escaping ([(from: String, to: String, amount: Double)]) -> Void) {
        let groupRef = db.collection("groups").document(groupId)
        
        groupRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let membersData = data["members"] as? [[String: Any]] else {
                completion([])
                return
            }
            
            let memberIds = membersData.compactMap { $0["id"] as? String }
            var transactions: [(from: String, to: String, amount: Double)] = []
            
            groupRef.collection("expenses").getDocuments { expSnapshot, error in
                guard let docs = expSnapshot?.documents else {
                    completion([])
                    return
                }
                
                for doc in docs {
                    if let expense = try? doc.data(as: Expense.self) {
                        switch expense.splitMethod {
                        case "equal":
                            let share = expense.amount / Double(memberIds.count)
                            for memberId in memberIds {
                                if memberId != expense.paidBy {
                                    transactions.append((from: memberId, to: expense.paidBy, amount: share))
                                }
                            }
                        case "custom":
                            if let splits = expense.customSplit {
                                for (memberId, share) in splits {
                                    if memberId != expense.paidBy {
                                        transactions.append((from: memberId, to: expense.paidBy, amount: share))
                                    }
                                }
                            }
                        default:
                            break
                        }
                    }
                }
                
                completion(transactions)
            }
        }
    }
    
    // MARK: - 群組刪除
    func deleteGroup(_ group: ExpenseGroup, completion: ((Error?) -> Void)? = nil) {
        guard let groupId = group.id else {
            completion?(NSError(domain: "MissingGroupID", code: 0, userInfo: nil))
            return
        }
        
        let groupRef = db.collection("groups").document(groupId)
        
        groupRef.collection("expenses").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                for doc in docs {
                    doc.reference.delete()
                }
            }
            groupRef.delete(completion: completion)
        }
    }
}
