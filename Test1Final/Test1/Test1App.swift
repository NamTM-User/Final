//
//  Test1App.swift
//  Test1
//
//  Created by Hai Nam on 11/5/26.
//

import SwiftUI

@main
struct Test1App: App {
    
    var body: some Scene {
        WindowGroup {
            ProjectListView()
                .environment(ProjectModel())
                .preferredColorScheme(.light)
        }
    }
}
