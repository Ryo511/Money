//
//  ShoppingRecordStore.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

struct ShoppingRecord: Identifiable {
    let id = UUID()
    let category: String  // 類別，例如「帳單」「飲食」
    let name: String
    let date: Date
    let amount: Double
    let location: String
}

class ShoppingRecordStore: ObservableObject {
    @Published var records: [ShoppingRecord] = []
    
    func addRecord(name: String, date: Date, category: String, amount: Double, location: String) {
        records.append(ShoppingRecord(category: category, name: name, date: date, amount: amount, location: location))
    }
    
    func records(for date: Date) -> [ShoppingRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
