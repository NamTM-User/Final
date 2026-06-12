//
//  ProjectSingle.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import SwiftUI


struct ProjectSingle: View {
    let project: Project
    var onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    private let swipeDistance: CGFloat = 50
    
    private var swipeOpacity: CGFloat {
        let absOffset = abs(offset)
        return min(1, max(0, absOffset / swipeDistance))
    }
    
    var body: some View {
        // container 1
        ZStack (alignment: .trailing) {
            // 1. Button delete
            Button {
                onDelete()
            } label: {
                Image(systemName: "minus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color(white: 0.8))
                    .clipShape(Circle())
                    .opacity(swipeOpacity) // hiệu ứng kéo ra kéo vào thay đổi opacity
                    .scaleEffect(0.6 + (swipeOpacity * 0.4) ) // scale
            }
            .padding(.trailing , 16)
            
            // 2. Render Project
            NavigationLink(value: project) {
                HStack {
                    Text(project.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                    
                    Spacer()
                }
                .padding(.horizontal , 24)
                .frame(height: 70)
                .background(Color(white: 0.95))
                .cornerRadius(18)
            }
            .buttonStyle(.plain)
            .padding(.leading , 16)
            
            //handle slider
            .padding(.trailing, 16 - offset)
            .highPriorityGesture(
                DragGesture()
                
                    // changed
                    .onChanged { value in
                        let startOffset: CGFloat = isSwiped ? -swipeDistance : 0
                        var newOffset: CGFloat = startOffset + value.translation.width
                        let elastic: CGFloat = 15 // là độ đàn hồi cải thiện UX
                        let maxleft: CGFloat = swipeDistance + elastic
                        
                        // max drag right
                        newOffset = min(0 , newOffset) // newOffset vì kéo sang trái nên giá trị không đc dương
                        
                        // max drag left
                        newOffset = max( -maxleft , newOffset)
                        
                        offset = newOffset
                    }
                    
                    // end changed
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3 , dampingFraction: 0.7)) {
                            let startOffset: CGFloat = isSwiped ? -swipeDistance : 0
                            let endOffset: CGFloat = startOffset + value.translation.width
                            let s: CGFloat = -(swipeDistance * 0.5)
                            
                            // Nếu kéo được 50% quãng đường thì bỏ tay ra cho kéo hết, ko thì cho về như ban đầu
                            if endOffset < s {
                                offset = -swipeDistance // đàn hồi ở đây! cho phép kéo thêm , bỏ tay ra về = swipeDistance đã cố định
                                isSwiped = true
                            }
                            else {
                                offset = 0
                                isSwiped = false
                            }
                        }
                    }
            )
        }
    }
}
