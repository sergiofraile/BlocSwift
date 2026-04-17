//
//  LorcanaNetworkService.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Alamofire
import Foundation

/// Network service for fetching Lorcana card data
final class LorcanaNetworkService: LorcanaNetworkServiceProtocol, @unchecked Sendable {
    
    enum Constants {
        static let baseURL = "https://api.lorcana-api.com"
        static let defaultPageSize = 100
    }
    
    /// Fetches all cards with pagination
    /// - Parameters:
    ///   - page: The page number (1-based)
    ///   - pageSize: Number of cards per page (default 100, max 1000)
    /// - Returns: Array of Lorcana cards
    func fetchAllCards(page: Int = 1, pageSize: Int = Constants.defaultPageSize) async throws -> [LorcanaCard] {
        let url = "\(Constants.baseURL)/cards/all"
        let parameters: [String: Any] = [
            "page": page,
            "pagesize": pageSize
        ]
        
        let response = try await AF
            .request(url, parameters: parameters)
            .serializingDecodable([LorcanaCard].self)
            .value
        
        return response
    }
    
    /// Searches for cards matching a query by name (partial match)
    /// - Parameters:
    ///   - query: The search query (partial name match using ~ operator)
    ///   - page: The page number (1-based)
    ///   - pageSize: Number of cards per page (default 100, max 1000)
    /// - Returns: Array of matching Lorcana cards
    func searchCards(query: String, page: Int = 1, pageSize: Int = Constants.defaultPageSize) async throws -> [LorcanaCard] {
        // Use the /cards/fetch endpoint with search parameter
        // The ~ operator is for partial/contains matching: name~daisy
        let url = "\(Constants.baseURL)/cards/fetch"
        let searchQuery = "name~\(query)"
        let parameters: [String: Any] = [
            "search": searchQuery,
            "page": page,
            "pagesize": pageSize
        ]
        
        let response = try await AF
            .request(url, parameters: parameters)
            .serializingDecodable([LorcanaCard].self)
            .value
        
        return response
    }
    
    /// Fetches all cards from a specific set
    /// - Parameters:
    ///   - setName: The name of the set
    ///   - page: The page number (1-based)
    ///   - pageSize: Number of cards per page (default 100, max 1000)
    /// - Returns: Array of Lorcana cards from the set
    func fetchCardsFromSet(setName: String, page: Int = 1, pageSize: Int = Constants.defaultPageSize) async throws -> [LorcanaCard] {
        let url = "\(Constants.baseURL)/cards/fetch"
        let searchQuery = "set_name=\(setName)"
        let parameters: [String: Any] = [
            "search": searchQuery,
            "page": page,
            "pagesize": pageSize
        ]
        
        let response = try await AF
            .request(url, parameters: parameters)
            .serializingDecodable([LorcanaCard].self)
            .value
        
        return response
    }
    
    /// Fetches all available sets
    /// - Returns: Array of Lorcana sets
    func fetchSets() async throws -> [LorcanaSet] {
        let url = "\(Constants.baseURL)/sets/fetch"
        
        let response = try await AF
            .request(url)
            .serializingDecodable([LorcanaSet].self)
            .value
        
        return response
    }
}
