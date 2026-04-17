//
//  FormulaOneNetworkService.swift
//  BlocProject
//
//  Created by Sergio Fraile on 24/06/2025.
//

import Alamofire
import Foundation

/// A network service for fetching Formula One data.
// TODO: Try creating an actor for network services instead of a class
class FormulaOneNetworkService {

    func fetchDriversChampionship() async throws -> [DriverChampionship] {
        let url = "https://f1api.dev/api/current/drivers-championship"
        return try await AF
            .request(url)
            .serializingDecodable(DriversChampionshipResponse.self)
            .value
            .drivers_championship
    }
}
