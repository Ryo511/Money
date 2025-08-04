//
//  ShoppingRecord.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/08/03.
//


import Foundation
import FirebaseFirestore

struct ShoppingRecordd: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore 自動生成的文件ID
    var name: String
    var date: Date
    var category: String
    var amount: Double
    var location: String
}
