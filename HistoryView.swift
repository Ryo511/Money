//
//  HistoryView.swift
//  Money
//
//  Created by OLIVER LIAO on 2025/07/12.
//

import SwiftUI


struct HistoryView: View {
    @EnvironmentObject var store: ShoppingRecordStore
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = Date()
    
    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Text(monthYearString(from: currentDate))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: columns) {
                    ForEach(weekdaySymbols(), id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(daysInMonth(for: currentDate), id: \.self) { date in
                        if let date = date {
                            Button(action: {
                                selectedDate = date
                            }) {
                                Text("\(calendar.component(.day, from: date))")
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(isSameDay(date1: date, date2: selectedDate) ? Color.blue : Color.clear)
                                    .foregroundColor(isSameDay(date1: date, date2: selectedDate) ? .white : .black)
                                    .clipShape(Circle())
                            }
                        } else {
                            // 空格
                            Text("")
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    }
                }
                .padding()
                
                if let selectedDate = selectedDate {
                    Text("📅 \(formattedDate(selectedDate)) 的紀錄")
                        .font(.headline)
                    
                    List {
                        ForEach(store.records(for: selectedDate)) { record in
                            HStack {
                                Text("🛒 \(record.name)")
                                
                                Spacer()
                                
                                Text("💰 NT$\(String(format: "%.0f", record.amount))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("📍 \(record.location)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .frame(height: 200)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    // MARK: - 日期方法
    func daysInMonth(for date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // 轉換：若是星期日（1），就放到最後
        let weekdayOffset = (firstWeekday + 5) % 7 // 讓星期一為開頭（0）
        
        let dates: [Date?] = Array(repeating: nil, count: weekdayOffset) + range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
        
        return dates
    }
    
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
    
    func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    func isSameDay(date1: Date?, date2: Date?) -> Bool {
        guard let d1 = date1, let d2 = date2 else { return false }
        return calendar.isDate(d1, inSameDayAs: d2)
    }
    
    func weekdaySymbols() -> [String] {
        var symbols = calendar.shortStandaloneWeekdaySymbols
        let sunday = symbols.removeFirst()
        symbols.append(sunday)
        return symbols
    }
    
    func delete(at offsets: IndexSet) {
        let records = store.records(for: selectedDate!)
        for index in offsets {
            let record = records[index]
            store.delete(record)
        }
    }
}

#Preview {
    HistoryView().environmentObject(ShoppingRecordStore())
}
