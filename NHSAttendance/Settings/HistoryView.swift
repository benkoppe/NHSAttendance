//
//  HistoryView.swift
//  NHSAttendance
//
//  Created by Ben K on 9/21/21.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var history: [Date: [String]] = [:]
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        NavigationView {
            Group {
                if history.isEmpty {
                    Text("There is currently no history.")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(Array(history.keys).sorted().reversed(), id: \.self) { date in
                            if let names = history[date] {
                                Section(header: Text(dateFormatter.string(from: date))) {
                                    ForEach(names.sorted(), id: \.self) { name in
                                        Text(name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                    }
                }
            }
        }
        .onAppear {
            let userDefaults = UserDefaults.standard
            if let decoded = userDefaults.data(forKey: "history"), let readData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as? [Date: [String]] {
                history = readData
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
