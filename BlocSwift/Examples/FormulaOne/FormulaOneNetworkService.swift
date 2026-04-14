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

    private static let session: Session = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        return Session(configuration: config)
    }()

    func fetchDriversChampionship() async throws -> [DriverChampionship] {
        let url = "https://f1api.dev/api/current/drivers-championship"
        return try await Self.session
            .request(url)
            .serializingDecodable(DriversChampionshipResponse.self)
            .value
            .drivers_championship
    }
}
