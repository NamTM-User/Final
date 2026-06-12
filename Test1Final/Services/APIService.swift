//
//  APIService.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation

struct APIService {
    // A. MARK: - GET API
    func getAPI() async throws -> ProjectLists {
        guard let url = URL(string: "https://tapuniverse.com/xproject") else { throw URLError(.badURL)}
        
        // get data from server
        let (data , _) = try await URLSession.shared.data(from: url)
        // parse JSON
        let res = try JSONDecoder().decode(ProjectLists.self, from: data)
        return res
    }
    
    // B. MARK: - POST
    func postAPI(projectId: Int) async throws -> ProjectDetail {
        guard let url = URL(string: "https://tapuniverse.com/xprojectdetail") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        
        // 1. HTTP request method
        request.httpMethod = "POST"
        
        // 2. Header
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 3. Body
        let body: [String: Int] = ["id" : projectId]
    
        request.httpBody = try JSONEncoder().encode(body)  // parse object -> JSON
        
        // 4. Send reques -> Server
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // 5. Parse JSON Data
        let res = try JSONDecoder().decode(ProjectDetail.self, from: data)
        
        return res
        
    }
}
