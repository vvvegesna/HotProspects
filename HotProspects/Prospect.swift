//
//  Prospect.swift
//  HotProspects
//
//  Created by Vegesna, Vijay V EX1 on 9/25/20.
//  Copyright © 2020 Vegesna, Vijay V. All rights reserved.
//

import SwiftUI

class Prospect: Identifiable, Codable {
    let id = UUID()
    let createdDate = Date()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
    
    func setContanct(_ value: Bool) {
        isContacted = value
    }
}

class Prospects: ObservableObject {
    @Published private(set) var people: [Prospect]
    static let saveKey = "SavedData"
    
    enum SortType {
        case name, recents
    }
    
    init() {
        //        if let data = UserDefaults.standard.data(forKey: "SavedData") {
        //            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
        //                self.people = decoded
        //                return
        //            }
        //        }
        self.people = []
    }
    
    func loadProspects() {
        let fileName = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
        do {
            let data = try Data(contentsOf: fileName)
            self.people = try JSONDecoder().decode([Prospect].self, from: data)
        } catch {
            print("Unable to load saved data")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }
    
    private func save() {
        let fileName = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
        
        if let encoded = try? JSONEncoder().encode(people) {
            //UserDefaults.standard.set(encoded, forKey: Self.saveKey)
            try? encoded.write(to: fileName, options: [.atomicWrite, .completeFileProtection])
        }
    }
    
    func sortPeople(by type: SortType) {
        switch type {
        case .name:
            people.sort {
                $0.name < $1.name
            }
        case .recents:
            people.sort {
                $0.createdDate < $1.createdDate
            }
        }
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
}
