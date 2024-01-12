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
    case usuallyLooksLikeThis = "usually_looks_like_this"
    case questStepCountTitle = "quest_step_count_title"
    
    var localized: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

//"quest_step_count_title"= "How many steps are here?"
//"quest_step_count_stile_hint" = "Just the number of steps to reach the top. If the step count differs on each side, give the higher number."
