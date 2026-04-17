//
//  Driver.swift
//  BlocSwift
//
//  Created by Sergio Fraile Carmena on 06/08/2025.
//

import Foundation

struct DriversChampionshipResponse: Decodable {
    let drivers_championship: [DriverChampionship]
}

struct DriverChampionship: Decodable {
    let classificationId: Int
    let position: Int
    let points: Int
    let wins: Int
    let driver: Driver
    let team: Team
}

extension DriverChampionship: Identifiable {
    var id: String {
        return String(classificationId)
    }
}

extension DriverChampionship: Equatable {
    static func == (lhs: DriverChampionship, rhs: DriverChampionship) -> Bool {
        return lhs.classificationId == rhs.classificationId
    }
}

struct Driver: Decodable {
    let name: String
    let surname: String
    let nationality: String
    let birthday: String
    let number: Int
    let shortName: String
}

extension Driver: Identifiable {
    var id: String {
        return String(number)
    }
}

extension Driver: Equatable {
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        return lhs.number == rhs.number &&
        lhs.name == rhs.name &&
        lhs.surname == rhs.surname
    }
}
    
struct Team: Decodable {
    let teamName: String
    let country: String
}
