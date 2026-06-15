//
//  PopupAddProject.swift
//  Test1
//
//  Created by Hai Nam on 14/5/26.
//
import SwiftUI


struct PopupAddProject: View {
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text("Add Project")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(.blue)
                .cornerRadius(20)
        }
        .padding(30)
    }
        
}
