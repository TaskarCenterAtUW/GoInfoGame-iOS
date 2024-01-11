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

    var localized: String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

