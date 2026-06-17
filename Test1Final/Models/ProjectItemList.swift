//
//  Project.swift
//  Test1Final
//
//  Created by Hai Nam on 12/6/26.
//

import Foundation

struct ProjectItem: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
}

struct ProjectLists: Codable {
    let projects: [ProjectItem]
}
