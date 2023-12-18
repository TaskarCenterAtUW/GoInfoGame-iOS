//
//  Highway.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 10/12/23.
//

import Foundation

let ALL_ROADS: Set<String> = [
    "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link",
    "secondary", "secondary_link", "tertiary", "tertiary_link",
    "unclassified", "residential", "living_street", "pedestrian",
    "service", "track", "road"
]

let ALL_PATHS: Set<String> = [
    "footway", "cycleway", "path", "bridleway", "steps"
]

let ROADS_ASSUMED_TO_BE_PAVED: [String] = [
    "trunk", "trunk_link", "motorway", "motorway_link"
]
