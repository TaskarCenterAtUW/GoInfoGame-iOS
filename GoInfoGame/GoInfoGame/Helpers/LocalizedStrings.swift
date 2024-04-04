//
//  LocalizedStrings.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import Foundation
enum LocalizedStrings: String {
    case questWidthMostNarrowPath = "quest_width_most_narrow_path"
    case questDetermineSidewalkWidth = "quest_determine_sidewalk_widths"
    case questRoadWithExplanation = "quest_road_width_explanation"
    case questGenericConfirmationTitle = "quest_generic_confirmation_title"
    case otherAnswers = "other_answers"
    case questionsList = "questions_list"
    case questRoadWidthUnusualInputConfirmation = "quest_road_width_unusualInput_confirmation_description"
    case questGenericConfirmationYes = "quest_generic_confirmation_yes"
    case questGenericConfirmationNo = "quest_generic_confirmation_no"
    case questSpecifyHandrails = "quest_specify_handrails"
    case questHandrailTitle = "quest_handrail_title"
    case questGenericHasFeatureYes = "quest_generic_hasFeature_yes"
    case questGenericHasFeatureNo = "quest_generic_hasFeature_no"
    case questGenericHasFeatureOptional = "quest_generic_hasFeature_optional"
    case questStepsRampTitle = "quest_steps_ramp_title"
    case select = "Select"
    case questStepsRampNone = "quest_steps_ramp_none"
    case questStepsRampBicycle = "quest_steps_ramp_bicycle"
    case questStepsRampStroller = "quest_steps_ramp_stroller"
    case questStepsRampWheelchair = "quest_steps_ramp_wheelchair"
    case questStepsInclineTitle = "quest_steps_incline_title"
    case questStepsInclineUp = "quest_steps_incline_up"
    case selectOne = "select_one"
    case questTactilePavingTitleSteps = "quest_tactilePaving_title_steps"
    case questTactilePavingCrossing = "quest_tactilePaving_crosswalk"
    case usuallyLooksLikeThis = "usually_looks_like_this"
    case questStepCountTitle = "quest_step_count_title"
    case questLitTitle = "quest_lit_title"
    case questBusStopLitTitle = "quest_busStopLit_title"
    case questCrossingTitle = "quest_crossing_title"
    case questCrossingYes = "quest_crossing_yes"
    case questCrossingNo = "quest_crossing_no"
    case questCrossingProhibited = "quest_crossing_prohibited"
    case cantSay = "cant_say"
    case questGenericAnswerDiffersAlongTheWay = "quest_generic_answer_differs_along_the_way"
    case questSidewalkTitle = "quest_sidewalk_title"
    case questSidewalkValueLeft = "quest_sidewalk_value_left"
    case questSidewalkValueRight = "quest_sidewalk_value_right"
    case questSidewalkValueNo = "quest_sidewalk_value_no"
    case questSidewalkValueBoth = "quest_sidewalk_value_both"
    case questSidewalkValueSeparate = "quest_sidewalk_value_separate"
    case questSidewalkValueNoSidewalkAtAll = "quest_sidewalk_value_no_sidewalk_at_all"
    case questSidewalkSurfaceTitle = "quest_sidewalk_surface_title"
    case questSurfaceValueGround = "quest_surface_value_ground"
    case questSurfaceValueAsphalt = "quest_surface_value_asphalt"
    case questSurfaceValueCompacted = "quest_surface_value_compacted"
    case questSurfaceValueConcrete = "quest_surface_value_concrete"
    case questSurfaceValueDirt = "quest_surface_value_dirt"
    case questSurfaceValueMud = "quest_surface_value_mud"
    case questSurfaceValueFineGravel = "quest_surface_value_fine_gravel"
    case questSurfaceValueGrass = "quest_surface_value_grass"
    case questSurfaceValueGrassPaver = "quest_surface_value_grass_paver"
    case questSurfaceValueGravel = "quest_surface_value_gravel"
    case questSurfaceValuePavingStones = "quest_surface_value_paving_stones"
    case questSurfaceValuePebblestone = "quest_surface_value_pebblestone"
    case questSurfaceValueSand = "quest_surface_value_sand"
    case questSurfaceValueRock = "quest_surface_value_rock"
    case questSurfaceValueSett = "quest_surface_value_sett"
    case questSurfaceValueWood = "quest_surface_value_wood"
    case questSurfaceValueWoodchips = "quest_surface_value_woodchips"
    case questSurfaceValueConcretePlates = "quest_surface_value_concrete_plates"
    case questSurfaceValueConcreteLanes = "quest_surface_value_concrete_lanes"
    case questSurfaceValueMetal = "quest_surface_value_metal"
    case questSurfaceValueUnhewnCobblestone = "quest_surface_value_unhewn_cobblestone"
    case questSurfaceValueClay = "quest_surface_value_clay"
    case questSurfaceValueArtificialTurf = "quest_surface_value_artificial_turf"
    case questSurfaceValueTartan = "quest_surface_value_tartan"
    case questSurfaceValuePaved = "quest_surface_value_paved"
    case questSurfaceValueUnpaved = "quest_surface_value_unpaved"
    case questLeaveNewNoteTitle = "quest_leave_new_note_title";
    case questLeaveNewNoteDescription = "quest_leave_new_note_description";
    case questLeaveNewNoteYes = "quest_leave_new_note_yes";
    case questLeaveNewNoteNo = "quest_leave_new_note_no";
    case questSourceDialogTitle = "quest_source_dialog_title";
    case questSourceDialogNote = "quest_source_dialog_note";
    case undoConfirmNegative = "undo_confirm_negative";
    case questStepsRampSeparateWheelchair = "quest_steps_ramp_separate_wheelchair"
    case questStepsRampSeparateWheelchairConfirm = "quest_steps_ramp_separate_wheelchair_confirm"
    case questStepsRampSeparateWheelchairDecline = "quest_steps_ramp_separate_wheelchair_decline"
    case questPedestrianCrossingIsland = "quest_pedestrian_crossing_island"
    case dontShowAgain = "dont_show_again"
    case questTactilePavingKerbTitle = "quest_tactile_paving_kerb_title"
    case questCrossingKerbHeightTitle = "quest_crossing_kerb_height_title"
    case questKerbHeightFlush = "quest_kerb_height_flush"
    case questKerbHeightLowered = "quest_kerb_height_lowered"
    case questKerbHeightRaised = "quest_kerb_height_raised"
    case questKerbHeightLoweredRamp = "quest_kerb_height_lowered_ramp"
    case questKerbHeightNo = "quest_kerb_height_no"
    case questCrossingTypeTitle = "quest_crossing_type_title"
    case questCrossingTypeSignalsControlled = "quest_crossing_type_signals_controlled"
    case questCrossingTypeMarked = "quest_crossing_type_marked"
    case questCrossingTypeUnmarked = "quest_crossing_type_unmarked"
    case questStairFlights = "quest_stair_flights"
    case questKerbHeightTitle = "quest_kerb_height_title"
    
    var localized: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}
