//
//  ProjectListView.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import SwiftUI

import SwiftUI

struct ProjectListView: View {
    @Environment(ProjectModel.self) private var store
    
    @State private var isShowAddAlert = false
    @State private var newNameProjet = ""
    
    var body: some View {
        NavigationStack {
                VStack {
                    
                    // 1. render list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(store.projects) { project in
                                ProjectSingle(project: project) {
                                    store.deleteProject(project: project)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    
                    // 2. add project
                    PopupAddProject() {
                        isShowAddAlert = true
                        
                    }
                    .alert("New Project", isPresented: $isShowAddAlert) {
                        TextField("?" , text: $newNameProjet)
                        
                        Button {
                            store.addProject(name: newNameProjet)
                            // delete
                            newNameProjet = ""
                        } label: {
                            Text("Add")
                        }

                        Button("Cancel", role: .cancel) {
                            newNameProjet = ""
                        }
                        
                    }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(white: 0.95))
                    
                    
                }
            
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { selectProject in
                ProjectDetailView(projectID: selectProject.id)
            }
            .task {
                do {
                    try await store.fetchProjects()
                } catch {
                    print("Loi~ fetch project")
                }
            }
            .preferredColorScheme(.light)
        }
    }
}


#Preview {
    ProjectListView().environment(ProjectModel())
}
