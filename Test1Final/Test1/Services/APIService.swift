//
//  APIService.swift
//  Test1
//
//  Created by Hai Nam on 11/5/26.
//

import Foundation

struct APIService {
    
    // 1. GET API
    func getAPI() async throws -> ProjectLists {
        guard let url = URL(string: "https://tapuniverse.com/xproject") else {
            // URLError là một kiểu lỗi có sẵn của Apple dành cho networking , .badURL là URL sai
            throw URLError(.badURL)
        }
        // get data from server
        let (data , _) = try await URLSession.shared.data(from: url)
            
        // parse JSON
        let res = try JSONDecoder().decode(ProjectLists.self, from: data)
        return res
    }
    
    // 2. POST
    func postAPI(projectId: Int) async throws -> ProjectDetail {
        guard let url = URL(string: "https://tapuniverse.com/xprojectdetail") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        
        // - 1. http request method
        request.httpMethod = "POST"
        
        // - 2. header
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // - 3. body
        let body: [String: Int] = ["id" : projectId]
        
        // swift object -> JSON
        request.httpBody = try JSONEncoder().encode(body)
        
        // - 4. send request -> server
        let (data , _) = try await URLSession.shared.data(for: request)
        
        // - 5. parse json data
        let res = try JSONDecoder().decode(ProjectDetail.self, from: data)
        
        return res
    }
    
}

