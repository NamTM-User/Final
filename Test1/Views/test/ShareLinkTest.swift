//
//  ShareLinkTest.swift
//  Test1
//
//  Created by Hai Nam on 27/5/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ShareLinkDemoView: View {
    
    let website = URL(string: "https://apple.com")!
    
    var body: some View {
        NavigationStack {
            List {
                
                // MARK: Share Text
                
                Section("Share Text") {
                    ShareLink(
                        item: "Hello from ShareLink!"
                    )
                }
                
                // MARK: Share URL
                
                Section("Share URL") {
                    ShareLink(
                        item: website
                    ) {
                        Label("Share Website", systemImage: "link")
                    }
                }
                
                // MARK: Share Image
                
                Section("Share Image") {
                    
                    if let image = UIImage(systemName: "star.fill") {
                        
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(
                                "Star Image"
                            )
                        ) {
                            Label(
                                "Share Image",
                                systemImage: "photo"
                            )
                        }
                    }
                }
                
                // MARK: Share Multiple Items
                
                Section("Share Multiple") {
                    
                    ShareLink(
                        items: [
                            "Hello!",
                            website.absoluteString
                        ]
                    ) {
                        Label(
                            "Share Text + URL",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                }
                
                // MARK: Share File
                
                Section("Share File") {
                    
                    if let fileURL = createTempTextFile() {
                        
                        ShareLink(
                            item: fileURL
                        ) {
                            Label(
                                "Share TXT File",
                                systemImage: "doc"
                            )
                        }
                    }
                }
                
                // MARK: Custom Preview
                
                Section("Custom Preview") {
                    
                    ShareLink(
                        item: website,
                        preview: SharePreview(
                            "Apple Website",
                            image: Image(systemName: "globe")
                        )
                    ) {
                        VStack(alignment: .leading) {
                            Text("Custom Share")
                                .font(.headline)
                            
                            Text("Has custom preview")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("ShareLink Demo")
        }
    }
    
    // MARK: Create Temp File
    
    func createTempTextFile() -> URL? {
        
        let text = "Hello ShareLink File"
        
        let tempURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("demo.txt")
        
        do {
            try text.write(
                to: tempURL,
                atomically: true,
                encoding: .utf8
            )
            
            return tempURL
            
        } catch {
            print(error)
            return nil
        }
    }
}

#Preview {
    ShareLinkDemoView()
}
