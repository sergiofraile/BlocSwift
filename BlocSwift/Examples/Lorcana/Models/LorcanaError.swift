//
//  LorcanaError.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Foundation

/// Errors that can occur when interacting with the Lorcana API
struct LorcanaError: Error, Equatable {
    let message: String
    
    init(message: String = "An error occurred while fetching Lorcana data") {
        self.message = message
    }
    
    var localizedDescription: String { message }
}
