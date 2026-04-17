//
//  LorcanaCard.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Foundation

/// Response wrapper for fetching multiple cards
struct LorcanaCardsResponse: Decodable {
    let data: [LorcanaCard]?
}

/// A Lorcana trading card with all its properties
struct LorcanaCard: Decodable, Identifiable, Equatable {
    let name: String
    let artist: String?
    let setName: String?
    let setNum: Int?
    let color: String?
    let image: String?
    let cost: Int?
    let inkable: Bool?
    let type: String?
    let classifications: String?
    let abilities: String?
    let flavorText: String?
    let franchises: String?
    let rarity: String?
    let strength: Int?
    let willpower: Int?
    let lore: Int?
    let cardNum: Int?
    let bodyText: String?
    let setId: String?
    
    var id: String {
        "\(setName ?? "unknown")-\(name)-\(cardNum ?? 0)"
    }
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case artist = "Artist"
        case setName = "Set_Name"
        case setNum = "Set_Num"
        case color = "Color"
        case image = "Image"
        case cost = "Cost"
        case inkable = "Inkable"
        case type = "Type"
        case classifications = "Classifications"
        case abilities = "Abilities"
        case flavorText = "Flavor_Text"
        case franchises = "Franchises"
        case rarity = "Rarity"
        case strength = "Strength"
        case willpower = "Willpower"
        case lore = "Lore"
        case cardNum = "Card_Num"
        case bodyText = "Body_Text"
        case setId = "Set_ID"
    }
    
    /// Returns the ink color for UI styling
    var inkColor: InkColor {
        InkColor(rawValue: color?.lowercased() ?? "") ?? .unknown
    }
}

/// Ink colors in Lorcana
enum InkColor: String {
    case amber, amethyst, emerald, ruby, sapphire, steel
    case unknown
    
    var displayName: String {
        rawValue.capitalized
    }
}
