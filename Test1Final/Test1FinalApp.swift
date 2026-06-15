//
//  Test1FinalApp.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import SwiftUI

@main
struct Test1FinalApp: App {
    var body: some Scene {
        WindowGroup {
            ProjectListView()
                .environment(ProjectModel())
                .preferredColorScheme(.light)
        }
    }
}
