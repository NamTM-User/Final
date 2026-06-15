//
//  ContentView.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import SwiftUI

struct ContentView: View {
    @State private var projectModel = ProjectModel()
    
    var body: some View {
        ProjectListView()
            .environment(projectModel)
    }
}

#Preview {
    ContentView()
}
