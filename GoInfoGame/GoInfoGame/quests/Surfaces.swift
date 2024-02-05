//
//  Surfaces.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/02/24.
//

import Foundation
// This file contains information related surface type questions
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
}
/// List of way type surfaces
let SELECTABLE_WAY_SURFACES: Set<String> = [
    "asphalt", "pavingStones", "concrete", "concretePlates", "concreteLanes",
    "sett", "unhewnCobblestone", "grassPaver", "wood", "metal",
    "compacted", "fineGravel", "gravel", "pebbles", "woodchips",
    "dirt", "mud", "grass", "sand", "rock",
    "paved", "unpaved", "ground"
]
extension Surface {
    var titleResId: String {
        switch self {
        case .asphalt, .chipseal: return LocalizedStrings.questSurfaceValueAsphalt.localized
            case .concrete: return LocalizedStrings.questSurfaceValueConcrete.localized
            case .concretePlates: return LocalizedStrings.questSurfaceValueConcretePlates.localized
            case .concreteLanes: return LocalizedStrings.questSurfaceValueConcreteLanes.localized
            case .fineGravel: return LocalizedStrings.questSurfaceValueFineGravel.localized
            case .pavingStones: return LocalizedStrings.questSurfaceValuePavingStones.localized
            case .compacted: return LocalizedStrings.questSurfaceValueCompacted.localized
            case .dirt, .soil, .earth: return ""
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
        }
    }
    
    var iconResId: String {
        switch self {
            case .asphalt, .chipseal: return ""
            case .concrete: return ""
            case .concretePlates: return ""
            case .concreteLanes: return ""
            case .fineGravel: return ""
            case .pavingStones: return ""
            case .compacted: return ""
            case .dirt, .soil, .earth: return ""
            case .mud: return ""
            case .sett: return ""
            case .unhewnCobblestone: return ""
            case .grassPaver: return ""
            case .wood: return ""
            case .woodchips: return ""
            case .metal, .metalGrid: return ""
            case .gravel: return ""
            case .pebbles: return ""
            case .grass: return ""
            case .sand: return ""
            case .rock: return ""
            case .clay: return ""
            case .artificialTurf: return ""
            case .tartan: return ""
            case .paved: return ""
            case .unpaved: return ""
            case .ground: return ""
        }
    }
}
