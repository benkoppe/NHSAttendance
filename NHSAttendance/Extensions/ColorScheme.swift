//
//  ColorScheme.swift
//  NHSAttendance
//
//  Created by Ben K on 9/18/21.
//

import SwiftUI

enum colorScheme: Int, Codable, Identifiable, CaseIterable, Hashable {
    case system = 0
    case dark = 1
    case light = 2
    
    var id: Int { rawValue }
    
    func getActualScheme() -> Optional<ColorScheme> {
        switch self {
        case .system:
            return .none
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}
