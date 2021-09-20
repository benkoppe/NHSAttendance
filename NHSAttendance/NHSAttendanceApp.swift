//
//  NHSAttendanceApp.swift
//  NHSAttendance
//
//  Created by Ben K on 9/17/21.
//

import SwiftUI

@main
struct NHSAttendanceApp: App {
    @AppStorage("colorScheme") var colorScheme: colorScheme = .system
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme.getActualScheme())
        }
    }
}
