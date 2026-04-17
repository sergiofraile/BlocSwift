//
//  LorcanaSet.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Foundation

/// Response wrapper for fetching sets
struct LorcanaSetsResponse: Decodable {
    let data: [LorcanaSet]?
}

/// A Lorcana card set
struct LorcanaSet: Decodable, Identifiable, Equatable {
    let setId: String
    let name: String
    let releaseDate: String?
    let totalCards: Int?
    
    var id: String { setId }
    
    enum CodingKeys: String, CodingKey {
        case setId = "Set_ID"
        case name = "Name"
        case releaseDate = "Release_Date"
        case totalCards = "Total_Cards"
    }
}
