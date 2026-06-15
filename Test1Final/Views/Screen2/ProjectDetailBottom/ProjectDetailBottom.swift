//
//  ProjectDetailBottom.swift
//  Test1
//
//  Created by Hai Nam on 15/5/26.
//

import SwiftUI
import PhotosUI

struct ProjectDetailBottom: View {
    var onAddPhoto: (Data) -> Void
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(spacing: 20) {

            
            // 2. add photo
            PhotosPicker(selection: $selectedItems,
                         maxSelectionCount: 10,
                         matching: .images) {
                Text("Add Photo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 40)
            .onChange(of: selectedItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                
                Task {
                    for item in newItems {
                        if let imgData = try? await item.loadTransferable(type: Data.self) {
                            onAddPhoto(imgData)
                        }
                    }
                    // Reset lại mảng để lần sau có thể chọn tiếp chính các ảnh này 
                    selectedItems.removeAll()
                }
            }
            
            
        }
        .frame(height: 150)
        .background(Color(white: 0.95))
    }
}
