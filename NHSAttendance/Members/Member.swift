//
//  Classes.swift
//  NHSAttendance
//
//  Created by Ben K on 9/17/21.
//

import Foundation

class Member: ObservableObject, Hashable, Identifiable, Comparable, Codable {
    @Published var firstName: String
    @Published var lastName: String
    @Published var grade: Int
    @Published var isHere: Bool
    let id: UUID
    
    var name: String {
        return firstName + " " + lastName
    }
    var revName: String {
        return lastName + ", " + firstName
    }
    
    init(firstName: String, lastName: String, grade: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.grade = grade
        self.isHere = false
        id = UUID()
    }
    
    static func == (lhs: Member, rhs: Member) -> Bool {
        return lhs.name == rhs.name
    }
    static func < (lhs: Member, rhs: Member) -> Bool {
        return lhs.name < rhs.name
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    enum CodingKeys: CodingKey {
        case firstName, lastName, grade, isHere, id
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        
        grade = try container.decode(Int.self, forKey: .grade)
        isHere = try container.decode(Bool.self, forKey: .isHere)
        id = try container.decode(UUID.self, forKey: .id)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(grade, forKey: .grade)
        try container.encode(isHere, forKey: .isHere)
        try container.encode(id, forKey: .id)
    }
}

class MemberArray: ObservableObject {
    @Published var members: [Member]
    
    var memberDictionary: Dictionary<String, [Member]> {
        return Dictionary(grouping: members, by: { member in
            let name = member.firstName
            let normalizedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let firstChar = String(normalizedName.first!).uppercased()
            return firstChar
        })
    }
    
    init() {
        var memberArray: [Member] = []
        
        for index in 0..<juniorLastNames.count {
            memberArray.append(Member(firstName: juniorFirstNames[index], lastName: juniorLastNames[index], grade: 11))
        }
        for index in 0..<seniorLastNames.count {
            memberArray.append(Member(firstName: seniorFirstNames[index], lastName: seniorLastNames[index], grade: 12))
        }
        
        memberArray.sort()
        
        self.members = memberArray
    }
    
    func saveHere() {
        let here = self.getHereNames()
        let userDefaults = UserDefaults.standard
        userDefaults.set(here, forKey: "here")
    }
    
    func fetchHere() {
        let userDefaults = UserDefaults.standard
        let hereNames: [String] = userDefaults.array(forKey: "here") as? [String] ?? []
        for member in members {
            if hereNames.contains(member.name) {
                member.isHere = true
            }
        }
    }
    
    func getHere() -> [Member] {
        var here: [Member] = []
        for member in members {
            if member.isHere {
                here.append(member)
            }
        }
        return here
    }
    
    func getHereNames() -> [String] {
        let here = getHere()
        var hereNames: [String] = []
        for hereMember in here {
            hereNames.append(hereMember.name)
        }
        return hereNames
    }
    
    func makeChunks(count: Int) -> [[Member]] {
        let sortedMembers = members.sorted {
            $0.lastName < $1.lastName
        }
        
        var chunkedMembers: [[Member]] = []
        let quadrant = Double(sortedMembers.count) / Double(count)
        var lastValue = 0.0
        for _ in 0 ..< count {
            let leftIndex = Int(lastValue)
            let rightIndex = Int(lastValue + quadrant)
            chunkedMembers.append(Array(sortedMembers[leftIndex ..< rightIndex]))
            lastValue += quadrant
        }
        
        return chunkedMembers
    }
    
    func getFilteredDictionary(name: String) -> Dictionary<String, [Member]> {
        var filteredMembers: [Member] = []
        for member in members {
            if member.name.lowercased().contains(name.lowercased()) {
                filteredMembers.append(member)
            }
        }
        return Dictionary(grouping: filteredMembers, by: { member in
            let name = member.firstName
            let normalizedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let firstChar = String(normalizedName.first!).uppercased()
            return firstChar
        })
    }
    
    func getFilteredDictionary(sortMode: SortModes, nameMode: NameModes, chunkMode: ChunkMode) -> Dictionary<String, [Member]> {
        var members: [Member] = []
        switch chunkMode {
        case .none:
            members = self.members
        case .chunked(let chunk):
            members = chunk
        }
        
        var filteredMembers: [Member] = []
        switch sortMode {
        case .none:
            filteredMembers = members
        case .here:
            for member in members {
                if member.isHere {
                    filteredMembers.append(member)
                }
            }
        case .notHere:
            for member in members {
                if !member.isHere {
                    filteredMembers.append(member)
                }
            }
        }
        filteredMembers.sort {
            switch nameMode {
            case .first:
                return $0.firstName < $1.firstName
            case .last:
                return $0.lastName < $1.lastName
            }
        }
        return Dictionary(grouping: filteredMembers, by: { member in
            let name = nameMode == .first ? member.firstName : member.lastName
            let normalizedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let firstChar = String(normalizedName.first!).uppercased()
            return firstChar
        })
    }
    
    func getFilteredDictionary(name: String, sortMode: SortModes, nameMode: NameModes, chunkMode: ChunkMode) -> Dictionary<String, [Member]> {
        var members: [Member] = []
        switch chunkMode {
        case .none:
            members = self.members
        case .chunked(let chunk):
            members = chunk
        }
        
        var filteredMembers: [Member] = []
        switch sortMode {
        case .none:
            for member in members {
                if member.name.lowercased().contains(name.lowercased()) {
                    filteredMembers.append(member)
                }
            }
        case .here:
            for member in members {
                if member.isHere {
                    if member.name.lowercased().contains(name.lowercased()) {
                        filteredMembers.append(member)
                    }
                }
            }
        case .notHere:
            for member in members {
                if !member.isHere {
                    if member.name.lowercased().contains(name.lowercased()) {
                        filteredMembers.append(member)
                    }
                }
            }
        }
        filteredMembers.sort {
            switch nameMode {
            case .first:
                return $0.firstName < $1.firstName
            case .last:
                return $0.lastName < $1.lastName
            }
        }
        return Dictionary(grouping: filteredMembers, by: { member in
            let name = nameMode == .first ? member.firstName : member.lastName
            let normalizedName = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let firstChar = String(normalizedName.first!).uppercased()
            return firstChar
        })
    }
    
    func clearHere() {
        for member in members {
            member.isHere = false
        }
    }
    
    func sendHere(completion: @escaping (Result<Data, SendError>) -> Void) {
        let url = URL(string: url)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = getHereNames().joined(separator: ",").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                completion(.failure(.expectedError))
            } else if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(.unexpectedError))
            }
        }.resume()
    }
}

enum SendError: Error {
    case expectedError, unexpectedError, failedLoad
}
