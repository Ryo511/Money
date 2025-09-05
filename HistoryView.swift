//
//  HistoryView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: ShoppingRecordStore
    @State private var selectedDate: Date = Date()
    let calendar = Calendar.current
    
    // 自訂顏色
    private let beigeColor = Color(red: 245/255, green: 245/255, blue: 220/255)
    private let grayColor = Color(red: 230/255, green: 230/255, blue: 230/255)
    
    var body: some View {
        VStack(spacing: 16) {
            
            // 月份標題
            Text(monthYearString(from: selectedDate))
                .font(.title2)
                .bold()
            
            // 半圓日期條
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(daysInMonth(for: selectedDate), id: \.self) { date in
                        if let date = date {
                            let amount = totalAmount(for: date)
                            let isSelected = isSameDay(date1: date, date2: selectedDate)
                            let topCategoryColor = colorForTopCategory(for: date)
                            
                            VStack(spacing: 2) {
                                // 週幾
                                Text(shortWeekday(for: date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                ZStack {
                                    // 外圈光暈（高額支出）
                                    Circle()
                                        .stroke(amount > 1000 ? Color.orange.opacity(0.7) : Color.clear, lineWidth: 3)
                                        .frame(width: isSelected ? 55 : 40, height: isSelected ? 55 : 40)
                                    
                                    // 主圓圈
                                    Circle()
                                        .fill(amount > 0 ? beigeColor : grayColor)
                                        .frame(width: isSelected ? 50 : 35, height: isSelected ? 50 : 35)
                                        .overlay(
                                            Text("\(calendar.component(.day, from: date))")
                                                .font(.caption)
                                                .foregroundColor(amount > 0 ? .black : .gray)
                                        )
                                }
                                
                                // 類別標記小圓點
                                if amount > 0 {
                                    Circle()
                                        .fill(topCategoryColor)
                                        .frame(width: 6, height: 6)
                                }
                                
                                // 當日總額
                                if amount > 0 {
                                    Text("NT$\(Int(amount))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 90)
            
            // 當日總額
            Text("💰 \(NSLocalizedString("TotalForDay", comment: "當日總支出")): NT$\(Int(totalAmount(for: selectedDate)))")
                .font(.headline)
            
            // 只在有資料時顯示圓餅圖
            let records = filteredRecords(for: selectedDate)
            if !records.isEmpty {
                PieChartView(records: records, defaultColor: grayColor)
                    .frame(height: 150)
                    .padding(.horizontal)
            }
            
            // 當日支出卡片列表
            if records.isEmpty {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("NoRecordsForDay", comment: "當日沒有支出紀錄"))
                        .foregroundColor(.gray)
                        .font(.headline)
                    Spacer()
                }
            } else {
                List {
                    ForEach(records) { record in
                        HStack {
                            Rectangle()
                                .fill(colorForCategory(record.category))
                                .frame(width: 8)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.name)
                                    .bold()
                                Text("📍 \(record.location)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("💰 NT$\(String(format: "%.0f", record.amount))")
                                .bold()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .scaleEffect(record.amount > 1000 ? 1.05 : 1.0)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(PlainListStyle())
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 刪除方法
    func delete(at offsets: IndexSet) {
        let records = filteredRecords(for: selectedDate)
        for index in offsets {
            let record = records[index]
            store.delete(record)
        }
    }
    
    // MARK: - Helper functions
    func daysInMonth(for date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    func isSameDay(date1: Date, date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    func filteredRecords(for date: Date) -> [ShoppingRecord] {
        store.records.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func totalAmount(for date: Date) -> Double {
        filteredRecords(for: date).map { $0.amount }.reduce(0, +)
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "帳單": return .blue
        case "購物": return .purple
        case "飲食": return .orange
        case "娛樂": return .pink
        case "交通": return .teal
        case "電話費": return .yellow
        default: return .gray
        }
    }
    
    func colorForTopCategory(for date: Date) -> Color {
        let records = filteredRecords(for: date)
        guard let maxRecord = records.max(by: { $0.amount < $1.amount }) else { return .clear }
        return colorForCategory(maxRecord.category)
    }
    
    func shortWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = NSLocalizedString("MonthYearFormat", comment: "")
        return formatter.string(from: date)
    }
}

// 🔹 PieChartView 改成支援 defaultColor
struct PieChartView: View {
    let records: [ShoppingRecord]
    var defaultColor: Color = Color.gray
    
    var body: some View {
        GeometryReader { geo in
            let total = records.map { $0.amount }.reduce(0, +)
            ZStack {
                if total == 0 {
                    Circle().fill(defaultColor)
                } else {
                    ForEach(records.indices, id: \.self) { index in
                        let startAngle = angle(for: index)
                        let endAngle = angle(for: index + 1)
                        Path { path in
                            path.move(to: CGPoint(x: geo.size.width/2, y: geo.size.height/2))
                            path.addArc(center: CGPoint(x: geo.size.width/2, y: geo.size.height/2),
                                        radius: min(geo.size.width, geo.size.height)/2,
                                        startAngle: startAngle,
                                        endAngle: endAngle,
                                        clockwise: false)
                        }
                        .fill(colorForCategory(records[index].category))
                    }
                }
            }
        }
    }
    
    func angle(for index: Int) -> Angle {
        let total = records.map { $0.amount }.reduce(0, +)
        let sum = records.prefix(index).map { $0.amount }.reduce(0, +)
        return Angle(degrees: total == 0 ? 0 : (sum/total) * 360)
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "帳單": return .blue
        case "購物": return .purple
        case "飲食": return .orange
        case "娛樂": return .pink
        case "交通": return .teal
        case "電話費": return .yellow
        default: return .gray
        }
    }
}

#Preview {
    HistoryView()
}
