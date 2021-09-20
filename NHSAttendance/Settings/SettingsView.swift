//
//  SettingsView.swift
//  NHSAttendance
//
//  Created by Ben K on 9/17/21.
//

import SwiftUI
import Introspect

enum AddModes: String, CaseIterable, Equatable {
    case tap, swipe
    var id: String { self.rawValue.capitalized }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        //NavigationView {
            Form {
                AddModePicker()
                NameModePicker()
                ColorSchemePicker()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        //}
    }
    
    struct AddModePicker: View {
        @AppStorage("AddMode") var addMode: AddModes = .tap
        
        var body: some View {
            Section {
                Picker("Add Mode", selection: $addMode) {
                    ForEach(AddModes.allCases, id: \.self) {
                        Text($0.id)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Add Mode")
            } footer: {
                Text("The way you will add students to the attendance.")
            }
        }
    }
    
    struct NameModePicker: View {
        @AppStorage("nameMode") var nameMode: NameModes = .first
        
        var body: some View {
            Section {
                Picker("Name Mode", selection: $nameMode) {
                    ForEach(NameModes.allCases, id: \.self) {
                        Text($0.id)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Name Mode")
            } footer: {
                Text("This will determine how names are sorted and displayed.")
            }
        }
    }
    
    struct ColorSchemePicker: View {
        @AppStorage("colorScheme") var colorScheme: colorScheme = .system
        
        var body: some View {
            Section {
                Picker("Color Scheme", selection: $colorScheme) {
                    Text("System").tag(Attendance.colorScheme.system)
                    Text("Dark").tag(Attendance.colorScheme.dark)
                    Text("Light").tag(Attendance.colorScheme.light)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Color Scheme")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
