//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Vegesna, Vijay V EX1 on 9/25/20.
//  Copyright © 2020 Vegesna, Vijay V. All rights reserved.
//

import SwiftUI
import CodeScanner
import UserNotifications

struct ProspectsView: View {
    
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    let filter: FilterType
    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner = false
    @State private var showingActionSheet = false
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Connected People"
        case .uncontacted:
            return "Unconnected People"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredProspects) { prospect in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if filter == .none {
                            Image(systemName: prospect.isContacted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(prospect.isContacted ? .green : .black)
                        }
                    }
                    .contextMenu {
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted") {
                            prospects.toggle(prospect)
                        }
                        if !prospect.isContacted {
                            Button("Remind me") {
                                addNotification(prospect)
                            }
                        }
                    }
                }
            }
            .onAppear(perform: prospects.loadProspects)
            .navigationBarTitle(title)
            .navigationBarItems(trailing: createTrailingButtons())
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: "Vegas\nDarling@domin.com", completion: handleScan)
            }
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(title: Text("Sort by"), buttons: [
                    .default(Text("Name")) {
                        prospects.sortPeople(by: .name)
                    },
                    .default(Text("Recents")) {
                        prospects.sortPeople(by: .recents)
                    },
                    .cancel()
                ])
            }
        }
    }
    
    private func createTrailingButtons() -> some View {
        HStack {
            Button("Sort") {
                showingActionSheet = true
            }
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            
            Button(action: {
                isShowingScanner = true
            }) {
                Image(systemName: "qrcode.viewfinder")
                Text("Scan")
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        self.isShowingScanner = false
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            switch filter {
            case .contacted:
                person.setContanct(true)
            case .uncontacted:
                person.setContanct(false)
            case .none:
                break
            }
            prospects.add(person)
        case .failure(let error):
            print("Scanning failed \(error.localizedDescription)")
        }
    }
    
    func addNotification(_ prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            //            var dateComponents = DateComponents()
            //            dateComponents.hour = 9
            //            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let tigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: tigger)
            center.add(request)
        }
        
        center.getNotificationSettings { setting in
            if setting.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
                    if success {
                        addRequest()
                    } else {
                        print(" authentication faild")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
