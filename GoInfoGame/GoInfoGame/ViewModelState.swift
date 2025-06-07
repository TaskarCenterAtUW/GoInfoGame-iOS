//
//  ViewModelState.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

enum ViewModelState<Context: Equatable>: Equatable {
    case idle
    case loading(Context)
    case loaded(Context)
    case error(String)
}
