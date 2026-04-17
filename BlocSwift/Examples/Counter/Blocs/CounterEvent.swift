//
//  CounterEvent.swift
//  BlocProject
//
//  Created by Sergio Fraile on 24/06/2025.
//

import Bloc

enum CounterEvent: BlocEvent {
    case increment
    case decrement
    case reset
}
