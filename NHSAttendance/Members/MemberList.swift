//
//  MemberList.swift
//  NHSAttendance
//
//  Created by Ben K on 9/17/21.
//

import SwiftUI
import Introspect

enum SortModes: String, CaseIterable, Equatable {
    case none, notHere, here
    
    var id: String { self.rawValue.capitalized }
}
enum NameModes: String, CaseIterable, Equatable {
    case first, last
    
    var id: String { self.rawValue.capitalized }
}
enum ChunkMode {
    case none
    case chunked([Member])
}

struct MemberList: View {
    @StateObject var memberArray = MemberArray()
    
    @State private var search: String = ""
    @State private var sort: SortModes = .none
    @AppStorage("nameMode") var nameMode: NameModes = .first
    @AppStorage("alwaysSearch") var searchMode: Bool = true
    
    @AppStorage("chunksEnabled") var chunksEnabled: Bool = false
    @State private var showChunks = false
    @AppStorage("totalChunks") var totalChunks: Int = 4
    @AppStorage("yourChunk") var yourChunk: Int = 0
    
    @State private var lastChange: Member? = nil
    
    @State private var settings = false
    @State private var submit = false
    @State private var clear = false
    
    var memberDictionary: Dictionary<String, [Member]> {
        if !chunksEnabled || yourChunk >= totalChunks {
            if search == "" {
                return memberArray.getFilteredDictionary(sortMode: sort, nameMode: nameMode, chunkMode: .none)
            } else {
                return memberArray.getFilteredDictionary(name: search, sortMode: sort, nameMode: nameMode, chunkMode: .none)
            }
        } else {
            let chunk = memberArray.makeChunks(count: totalChunks)[yourChunk]
            if search == "" {
                return memberArray.getFilteredDictionary(sortMode: sort, nameMode: nameMode, chunkMode: .chunked(chunk))
            } else {
                return memberArray.getFilteredDictionary(name: search, sortMode: sort, nameMode: nameMode, chunkMode: .chunked(chunk))
            }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(self.memberDictionary.keys.sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        if let shortMemberArray = self.memberDictionary[key] {
                            ForEach(shortMemberArray, id: \.self) { member in
                                MemberItem(member: member, lastChange: $lastChange)
                            }
                        }
                    }
                    .id(key)
                }
            }
            .searchable(text: $search, placement: UIDevice.current.userInterfaceIdiom == .pad ? .automatic : .navigationBarDrawer(displayMode: searchMode ? .always : .automatic))
            .listStyle(.insetGrouped)
            .alert("Are you sure?", isPresented: $clear) {
                Button("Clear", role: .destructive) {
                    memberArray.objectWillChange.send()
                    memberArray.clearHere()
                    memberArray.saveHere()
                }
            } message: {
                Text("Do you really want to clear the attendance?")
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(role: .destructive) {
                        clear = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    Button(action: {
                        if let lastChange = lastChange {
                            for member in memberArray.members {
                                if member == lastChange {
                                    withAnimation { member.isHere.toggle() }
                                    self.lastChange = nil
                                }
                            }
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(lastChange == nil)
                    Spacer()
                    Picker("Sort Mode", selection: $sort) {
                        ForEach(SortModes.allCases, id: \.self) { value in
                            switch value {
                            case .none:
                                Text("No Sort")
                            case .here:
                                Image(systemName: "checkmark.circle")
                            case .notHere:
                                Image(systemName: "xmark.circle")
                            }
                        }
                    }
                    .pickerStyle(.inline)
                    .scaleEffect(0.8)
                    Spacer()
                    /*Menu {
                        ForEach(self.memberDictionary.keys.sorted(), id: \.self) { key in
                            Button(key) {
                                withAnimation { proxy.scrollTo(key, anchor: .top) }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                    }*/
                    Toggle("Enable Splitting", isOn: $showChunks)
                        .labelsHidden()
                        .tint(.blue)
                        .toggleStyle(.switch)
                        .scaleEffect(0.9)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Button(action: {
                            submit = true
                        }) {
                            Text("Submit")
                                .padding()
                        }
                        .disabled(memberArray.getHere().isEmpty)
                    }
                }
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                NavigationLink(destination: SettingsView().environmentObject(memberArray)) {
                    Image(systemName: "gear")
                }
                if let url = URL(string: sheetURL) {
                    Link(destination: url) {
                        Image(systemName: "arrowshape.turn.up.forward")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Button(action: {
                        submit = true
                    }) {
                        Text("Submit")
                    }
                    .disabled(memberArray.getHere().isEmpty)
                }
            }
        }
        .sheet(isPresented: $submit) {
            SubmitView()
        }
        .sheet(isPresented: $settings) {
            SettingsView()
        }
        .environmentObject(memberArray)
        .onAppear {
            memberArray.objectWillChange.send()
            memberArray.fetchHere()
            showChunks = chunksEnabled
        }
        .onChange(of: showChunks) { newValue in
            memberArray.objectWillChange.send()
            self.chunksEnabled = newValue
        }
        .introspectViewController { viewController in
            
        }
    }
    
    struct MemberItem: View {
        @ObservedObject var member: Member
        @AppStorage("AddMode") var addMode: AddModes = .tap
        @EnvironmentObject var memberArray: MemberArray
        
        @Binding var lastChange: Member?
        
        var body: some View {
            switch addMode {
            case .tap:
                Button(action: {
                    onTap()
                }) {
                    MemberItemInsides(member: member)
                }
                .buttonStyle(.borderless)
            case .swipe:
                MemberItemInsides(member: member)
                    .swipeActions {
                        Button {
                            onSlide(adding: !member.isHere)
                        } label: {
                            Label(!member.isHere ? "Add" : "Remove", systemImage: !member.isHere ? "plus" : "minus")
                        }
                        .tint(!member.isHere ? .green : .red)
                    }
            case .both:
                Button(action: {
                    onTap()
                }) {
                    MemberItemInsides(member: member)
                }
                .buttonStyle(.borderless)
                .swipeActions {
                    Button {
                        onSlide(adding: !member.isHere)
                    } label: {
                        Label(!member.isHere ? "Add" : "Remove", systemImage: !member.isHere ? "plus" : "minus")
                    }
                    .tint(!member.isHere ? .green : .red)
                }
            }
        }
        
        func onTap() {
            memberArray.objectWillChange.send()
            withAnimation { member.isHere.toggle() }
            lastChange = member
            memberArray.saveHere()
        }
        func onSlide(adding: Bool) {
            memberArray.objectWillChange.send()
            member.isHere = adding
            lastChange = member
            memberArray.saveHere()
        }
        
        struct MemberItemInsides: View {
            @ObservedObject var member: Member
            @AppStorage("nameMode") var nameMode: NameModes = .first
            
            var body: some View {
                HStack {
                    Text("\(member.grade)")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Spacer()
                    }
                    Text(nameMode == .first ? "\(member.firstName) **\(member.lastName)**" : "**\(member.lastName)**, \(member.firstName)")
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: member.isHere ? "checkmark.circle" : "xmark.circle")
                        .foregroundColor(member.isHere ? .green : .red)
                }
                .padding()
                .foregroundColor(.primary)
            }
        }
    }
}

struct MemberList_Previews: PreviewProvider {
    static var previews: some View {
        MemberList()
            .preferredColorScheme(.dark)
    }
}
