//
//  LorcanaEvent.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Bloc

/// Events that can be sent to the LorcanaBloc
enum LorcanaEvent: BlocEvent {
    /// Clear the current state and reset to initial
    case clear
    
    /// Fetch all cards (first page)
    case fetchAllCards
    
    /// Load the next page of cards (infinite scroll)
    case loadNextPage
    
    /// Search for cards with the given query
    case search(query: String)
    
    /// Load cards from a specific set
    case loadSet(setName: String)
    
    /// Load sets list
    case loadSets
}
