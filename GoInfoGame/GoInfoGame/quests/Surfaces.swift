//
//  Surfaces.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/02/24.
//

import Foundation

// This file contains information related to surface type questions

/// Enum defining various surface types
enum Surface: String {
    case asphalt = "asphalt"
    case concrete = "concrete"
    case concretePlates = "concrete:plates"
    case concreteLanes = "concrete:lanes"
    case fineGravel = "fine_gravel"
    case pavingStones = "paving_stones"
    case compacted = "compacted"
    case dirt = "dirt"
    case mud = "mud"
    case sett = "sett"
    case unhewnCobblestone = "unhewn_cobblestone"
    case grassPaver = "grass_paver"
    case wood = "wood"
    case woodchips = "woodchips"
    case metal = "metal"
    case gravel = "gravel"
    case pebbles = "pebblestone"
    case grass = "grass"
    case sand = "sand"
    case rock = "rock"
    case clay = "clay"
    case artificialTurf = "artificial_turf"
    case tartan = "tartan"
    // generic surfaces
    case paved = "paved"
    case unpaved = "unpaved"
    case ground = "ground"
    // extra values, handled as synonyms (not selectable)
    case earth = "earth" // synonym of "dirt"
    case chipseal = "chipseal" // subtype/synonym of asphalt
    case metalGrid = "metal_grid" // more specific than "metal"
    case soil = "soil" // synonym of earth
    case none = "none"
    case unknown = "unknown"
}

/// List of way type surfaces
let SELECTABLE_WAY_SURFACES: Set<String> = [
    "asphalt", "paving_stones", "concrete", "concrete:plates", "concrete:lanes",
    "sett", "unhewn_cobblestone", "grass_paver", "wood", "metal",
    "compacted", "fine_gravel", "gravel", "pebblestone", "woodchips",
    "dirt", "mud", "grass", "sand", "rock",
    "paved", "unpaved", "ground"
]

extension Surface {
    /// Computed property returning localized title strings for each surface type
    var titleResId: String {
        switch self {
        case .asphalt, .chipseal: return LocalizedStrings.questSurfaceValueAsphalt.localized
        case .concrete: return LocalizedStrings.questSurfaceValueConcrete.localized
        case .concretePlates: return LocalizedStrings.questSurfaceValueConcretePlates.localized
        case .concreteLanes: return LocalizedStrings.questSurfaceValueConcreteLanes.localized
        case .fineGravel: return LocalizedStrings.questSurfaceValueFineGravel.localized
        case .pavingStones: return LocalizedStrings.questSurfaceValuePavingStones.localized
        case .compacted: return LocalizedStrings.questSurfaceValueCompacted.localized
        case .dirt, .soil, .earth: return "dirt"
        case .mud: return LocalizedStrings.questSurfaceValueMud.localized
        case .sett: return LocalizedStrings.questSurfaceValueSett.localized
        case .unhewnCobblestone: return LocalizedStrings.questSurfaceValueUnhewnCobblestone.localized
        case .grassPaver: return LocalizedStrings.questSurfaceValueGrassPaver.localized
        case .wood: return LocalizedStrings.questSurfaceValueWood.localized
        case .woodchips: return LocalizedStrings.questSurfaceValueWoodchips.localized
        case .metal, .metalGrid: return LocalizedStrings.questSurfaceValueMetal.localized
        case .gravel: return LocalizedStrings.questSurfaceValueGravel.localized
        case .pebbles: return LocalizedStrings.questSurfaceValuePebblestone.localized
        case .grass: return LocalizedStrings.questSurfaceValueGrass.localized
        case .sand: return LocalizedStrings.questSurfaceValueSand.localized
        case .rock: return LocalizedStrings.questSurfaceValueRock.localized
        case .clay: return LocalizedStrings.questSurfaceValueClay.localized
        case .artificialTurf: return LocalizedStrings.questSurfaceValueArtificialTurf.localized
        case .tartan: return LocalizedStrings.questSurfaceValueTartan.localized
        case .paved: return LocalizedStrings.questSurfaceValuePaved.localized
        case .unpaved: return LocalizedStrings.questSurfaceValueUnpaved.localized
        case .ground: return LocalizedStrings.questSurfaceValueGround.localized
        case .unknown: return "unknown"
        case .none: return ""
        }
    }
    
    /// Computed property returning icon names for each surface type
    var iconResId: String {
        switch self {
        case .asphalt, .chipseal: return "surface_asphalt"
        case .concrete: return "surface_concrete"
        case .concretePlates: return "surface_concrete_plates"
        case .concreteLanes: return "surface_concrete_lanes"
        case .fineGravel: return "surface_fine_gravel"
        case .pavingStones: return "surface_paving_stones"
        case .compacted: return "surface_compacted"
        case .dirt, .soil, .earth: return "surface_dirt"
        case .mud: return "surface_mud"
        case .sett: return "surface_sett"
        case .unhewnCobblestone: return "surface_cobblestone"
        case .grassPaver: return "surface_grass_paver"
        case .wood: return "surface_wood"
        case .woodchips: return "surface_woodchips"
        case .metal, .metalGrid: return "surface_metal"
        case .gravel: return "surface_gravel"
        case .pebbles: return "surface_pebblestone"
        case .grass: return "surface_grass"
        case .sand: return "surface_sand"
        case .rock: return "surface_rock"
        case .clay: return "surface_tennis_clay"
        case .artificialTurf: return "surface_artificial_turf"
        case .tartan: return "surface_tartan"
        case .paved: return "surface_paved_area"
        case .unpaved: return "surface_unpaved_area"
        case .ground: return "surface_ground_area"
        case .unknown: return ""
        case .none: return ""
        }
    }
}
