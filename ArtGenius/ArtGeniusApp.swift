//
//  ArtGeniusApp.swift
//  ArtGenius
//
//  Created by Ezagor on 18.11.2023.
//

import SwiftUI

@main
struct ArtGeniusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
