//
//  chatterApp.swift
//  chatter
//
//  Created by Mac mini on 06/09/2026.
//

import SwiftUI
import CoreData

@main
struct chatterApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
