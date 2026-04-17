//
//  FormulaOneState.swift
//  BlocProject
//
//  Created by Sergio Fraile on 24/06/2025.
//
enum FormulaOneState: Equatable {
    case initial
    case loading
    case loaded([DriverChampionship])
    case error(FormulaOneError)
}
