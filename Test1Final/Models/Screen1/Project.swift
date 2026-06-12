//
//  Project.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation


struct Project: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
}

struct ProjectLists: Codable {
    let projects: [Project]
}

