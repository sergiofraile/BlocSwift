//
//  LorcanaState.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Foundation

/// The state of the Lorcana Bloc
struct LorcanaState: Equatable {
    /// The list of cards currently loaded
    var cards: [LorcanaCard]
    
    /// The list of available sets
    var sets: [LorcanaSet]
    
    /// The current search query
    var searchQuery: String
    
    /// The current page for pagination
    var currentPage: Int
    
    /// Whether there are more pages to load
    var hasMorePages: Bool
    
    /// Whether the bloc is currently loading
    var isLoading: Bool
    
    /// Whether the bloc is loading the next page
    var isLoadingMore: Bool
    
    /// Error message if any
    var error: LorcanaError?
    
    /// Whether we're in search mode
    var isSearching: Bool {
        !searchQuery.isEmpty
    }
    
    /// Initial state
    static let initial = LorcanaState(
        cards: [],
        sets: [],
        searchQuery: "",
        currentPage: 1,
        hasMorePages: true,
        isLoading: false,
        isLoadingMore: false,
        error: nil
    )
}
