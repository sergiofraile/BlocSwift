//
//  LorcanaNetworkServiceProtocol.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Foundation

/// Protocol defining the network operations for Lorcana card browsing.
///
/// This protocol enables dependency injection and mocking for testing.
/// Implement this protocol to create different network backends (real, mock, etc.).
protocol LorcanaNetworkServiceProtocol: Sendable {
    
    /// Fetches all cards with pagination
    /// - Parameters:
    ///   - page: The page number (1-based)
    ///   - pageSize: Number of cards per page (default 100, max 1000)
    /// - Returns: Array of Lorcana cards
    /// - Throws: Network or decoding errors on failure
    func fetchAllCards(page: Int, pageSize: Int) async throws -> [LorcanaCard]
    
    /// Searches for cards matching a query by name (partial match)
    /// - Parameters:
    ///   - query: The search query (partial name match)
    ///   - page: The page number (1-based)
    ///   - pageSize: Number of cards per page (default 100, max 1000)
    /// - Returns: Array of matching Lorcana cards
    /// - Throws: Network or decoding errors on failure
    func searchCards(query: String, page: Int, pageSize: Int) async throws -> [LorcanaCard]
    
    /// Fetches all cards from a specific set
    /// - Parameters:
    ///   - setName: The name of the set
    ///   - page: The page number (1-based)
    ///   - pageSize: Number of cards per page (default 100, max 1000)
    /// - Returns: Array of Lorcana cards from the set
    /// - Throws: Network or decoding errors on failure
    func fetchCardsFromSet(setName: String, page: Int, pageSize: Int) async throws -> [LorcanaCard]
    
    /// Fetches all available sets
    /// - Returns: Array of Lorcana sets
    /// - Throws: Network or decoding errors on failure
    func fetchSets() async throws -> [LorcanaSet]
}
