//
//  Project.swift
//  Test1
//
//  Created by Hai Nam on 11/5/26.
//

import Foundation

// define struct from JSON
struct Project: Identifiable ,Codable, Hashable {
    let id: Int
    let name: String
}

struct ProjectLists: Codable {
    let projects: [Project]
}

