//
//  ViewModelState.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

enum ViewModelState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
