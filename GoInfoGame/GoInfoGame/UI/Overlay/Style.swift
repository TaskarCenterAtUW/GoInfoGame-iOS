//
//  Style.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 10/12/23.
//

import Foundation

struct PolylineStyle {
    var stroke: StrokeStyle?
    var strokeLeft: StrokeStyle?
    var strokeRight: StrokeStyle?
    var label: String?
}

struct StrokeStyle {
    var color: String
    var dashed: Bool
}

struct PolygonStyle {
    var color: String
    var icon: String?
    var label: String?
}

struct PointStyle {
    var icon: String?
    var label: String?
}

struct SidewalkSides {
    let left: StrokeStyle
    let right: StrokeStyle
}
