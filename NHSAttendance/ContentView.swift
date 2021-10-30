//
//  ContentView.swift
//  NHSAttendance
//
//  Created by Ben K on 9/17/21.
//

import SwiftUI

struct ContentView: View {
    
    @State private var text = ""
    var body: some View {
        NavigationView {
            MemberList()
        }
        .navigationViewStyle(.stack)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
