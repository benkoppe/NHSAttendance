//
//  SubmitView.swift
//  NHSAttendance
//
//  Created by Ben K on 9/17/21.
//

import SwiftUI

struct SubmitView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var memberArray: MemberArray
    
    
    enum LoadType {
        case loading, unstarted, error, finished
    }
    @State private var state: LoadType = .unstarted
    @State private var sendError: SendError? = nil
    
    var body: some View {
        NavigationView {
            
            switch state {
            case .loading:
                ProgressView()
                    .interactiveDismissDisabled()
            case .unstarted:
                VStack {
                    Text("Are you sure?")
                        .font(.system(size: 30))
                        .bold()
                        .padding(.top)
                        .padding(.bottom, 5)
                    Text("Do you really want to submit these names?")
                        .padding(.bottom)
                    
                    List {
                        ForEach(memberArray.members, id: \.self) { member in
                            if member.isHere {
                                HStack {
                                    Text(member.name)
                                    Spacer()
                                    Text("\(member.grade)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
                .navigationTitle("Submit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Submit") {
                            state = .loading
                            memberArray.sendHere() { result in
                                switch result {
                                case .success(_):
                                    print("setting finished")
                                    self.state = .finished
                                    DispatchQueue.main.async {
                                        memberArray.objectWillChange.send()
                                        memberArray.clearHere()
                                        memberArray.saveHere()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            dismiss()
                                        }
                                    }
                                case .failure(let error):
                                    sendError = error
                                    self.state = .error
                                }
                            }
                        }
                    }
                }
                .introspectNavigationController { navigationController in
                    navigationController.navigationBar.scrollEdgeAppearance = UINavigationBar().standardAppearance
                    navigationController.navigationBar.isTranslucent = true
                }
            case .error:
                VStack {
                    Spacer()
                    Text("ERROR")
                        .bold()
                        .padding()
                        .foregroundColor(.red)
                    if let sendError = sendError {
                        Text("\(sendError.localizedDescription.capitalized)")
                    }
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            case .finished:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .font(.title)
                    .padding()
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        for offset in offsets {
            memberArray.objectWillChange.send()
            memberArray.members[offset].isHere = false
            memberArray.saveHere()
        }
    }
}

struct SubmitView_Previews: PreviewProvider {
    static var previews: some View {
        SubmitView()
    }
}
