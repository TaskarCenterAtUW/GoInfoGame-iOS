// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Localizable {
    /// Accessibility Mode
    internal static let accessibilityMode = L10n.tr("Localizable", "Accessibility Mode", fallback: "Accessibility Mode")
    /// AVIV ScoutRoute
    internal static let appName = L10n.tr("Localizable", "App Name", fallback: "AVIV ScoutRoute")
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "Cancel", fallback: "Cancel")
    /// Can't Say
    internal static let cantSay = L10n.tr("Localizable", "cant_say", fallback: "Can't Say")
    /// Compose a note
    internal static let composeANote = L10n.tr("Localizable", "Compose a note", fallback: "Compose a note")
    /// Compose message
    internal static let composeMessage = L10n.tr("Localizable", "Compose message", fallback: "Compose message")
    /// Date & Time
    internal static let dateTime = L10n.tr("Localizable", "Date & Time", fallback: "Date & Time")
    /// Don't show again for this session
    internal static let dontShowAgain = L10n.tr("Localizable", "dont_show_again", fallback: "Don't show again for this session")
    /// Go back to map view
    internal static let goBackToMapView = L10n.tr("Localizable", "Go back to map view", fallback: "Go back to map view")
    /// Go back to previous screen
    internal static let goBackToPreviousScreen = L10n.tr("Localizable", "Go back to previous screen", fallback: "Go back to previous screen")
    /// Hide this quest
    internal static let hideThisQuest = L10n.tr("Localizable", "Hide this quest", fallback: "Hide this quest")
    /// Invalid credentials
    internal static let invalidCredentials = L10n.tr("Localizable", "Invalid credentials", fallback: "Invalid credentials")
    /// My Profile
    internal static let myProfile = L10n.tr("Localizable", "My Profile", fallback: "My Profile")
    /// Not now
    internal static let notNow = L10n.tr("Localizable", "Not now", fallback: "Not now")
    /// Number of quests:
    internal static let numberOfQuests = L10n.tr("Localizable", "Number of quests:", fallback: "Number of quests:")
    /// OTHER ANSWERS...
    internal static let otherAnswers = L10n.tr("Localizable", "other_answers", fallback: "OTHER ANSWERS...")
    /// Preferences
    internal static let preferences = L10n.tr("Localizable", "Preferences", fallback: "Preferences")
    /// Quest Type
    internal static let questType = L10n.tr("Localizable", "Quest Type", fallback: "Quest Type")
    /// Are there one or more street lamps within 10 feet of this Bus stop?
    internal static let questBusStopLitTitle = L10n.tr("Localizable", "quest_busStopLit_title", fallback: "Are there one or more street lamps within 10 feet of this Bus stop?")
    /// What’s the height of the curbs at this crossing?
    internal static let questCrossingKerbHeightTitle = L10n.tr("Localizable", "quest_crossing_kerb_height_title", fallback: "What’s the height of the curbs at this crossing?")
    /// No
    internal static let questCrossingNo = L10n.tr("Localizable", "quest_crossing_no", fallback: "No")
    /// Is this crossing marked?
    internal static let questCrossingTitle = L10n.tr("Localizable", "quest_crossing_title", fallback: "Is this crossing marked?")
    /// Marked
    internal static let questCrossingTypeMarked = L10n.tr("Localizable", "quest_crossing_type_marked", fallback: "Marked")
    /// Controlled by traffic lights
    internal static let questCrossingTypeSignalsControlled = L10n.tr("Localizable", "quest_crossing_type_signals_controlled", fallback: "Controlled by traffic lights")
    /// What kind of crossing is this?
    internal static let questCrossingTypeTitle = L10n.tr("Localizable", "quest_crossing_type_title", fallback: "What kind of crossing is this?")
    /// Without road markings
    internal static let questCrossingTypeUnmarked = L10n.tr("Localizable", "quest_crossing_type_unmarked", fallback: "Without road markings")
    /// Yes
    internal static let questCrossingYes = L10n.tr("Localizable", "quest_crossing_yes", fallback: "Yes")
    /// What is the width of the most narrow usable path along this footpath? 
    internal static let questDetermineSidewalkWidths = L10n.tr("Localizable", "quest_determine_sidewalk_widths", fallback: "What is the width of the most narrow usable path along this footpath? ")
    /// Differs along the way…
    internal static let questGenericAnswerDiffersAlongTheWay = L10n.tr("Localizable", "quest_generic_answer_differs_along_the_way", fallback: "Differs along the way…")
    /// I WILL CHECK
    internal static let questGenericConfirmationNo = L10n.tr("Localizable", "quest_generic_confirmation_no", fallback: "I WILL CHECK")
    /// Are you sure?
    internal static let questGenericConfirmationTitle = L10n.tr("Localizable", "quest_generic_confirmation_title", fallback: "Are you sure?")
    /// Yes, I am sure
    internal static let questGenericConfirmationYes = L10n.tr("Localizable", "quest_generic_confirmation_yes", fallback: "Yes, I am sure")
    /// No
    internal static let questGenericHasFeatureNo = L10n.tr("Localizable", "quest_generic_hasFeature_no", fallback: "No")
    /// Optionally
    internal static let questGenericHasFeatureOptional = L10n.tr("Localizable", "quest_generic_hasFeature_optional", fallback: "Optionally")
    /// Yes
    internal static let questGenericHasFeatureYes = L10n.tr("Localizable", "quest_generic_hasFeature_yes", fallback: "Yes")
    /// Do these steps have a handrail?
    internal static let questHandrailTitle = L10n.tr("Localizable", "quest_handrail_title", fallback: "Do these steps have a handrail?")
    /// Same level as road surface
    internal static let questKerbHeightFlush = L10n.tr("Localizable", "quest_kerb_height_flush", fallback: "Same level as road surface")
    /// A bit higher than road surface
    internal static let questKerbHeightLowered = L10n.tr("Localizable", "quest_kerb_height_lowered", fallback: "A bit higher than road surface")
    /// Curb ramp
    internal static let questKerbHeightLoweredRamp = L10n.tr("Localizable", "quest_kerb_height_lowered_ramp", fallback: "Curb ramp")
    /// No curb at all
    internal static let questKerbHeightNo = L10n.tr("Localizable", "quest_kerb_height_no", fallback: "No curb at all")
    /// High curb
    internal static let questKerbHeightRaised = L10n.tr("Localizable", "quest_kerb_height_raised", fallback: "High curb")
    /// What’s the height of this curb?
    internal static let questKerbHeightTitle = L10n.tr("Localizable", "quest_kerb_height_title", fallback: "What’s the height of this curb?")
    /// You can leave a public note for other mappers to resolve at this location, or hide this quest for yourself only
    internal static let questLeaveNewNoteDescription = L10n.tr("Localizable", "quest_leave_new_note_description", fallback: "You can leave a public note for other mappers to resolve at this location, or hide this quest for yourself only")
    /// Hide
    internal static let questLeaveNewNoteNo = L10n.tr("Localizable", "quest_leave_new_note_no", fallback: "Hide")
    /// Leave a note instead?
    internal static let questLeaveNewNoteTitle = L10n.tr("Localizable", "quest_leave_new_note_title", fallback: "Leave a note instead?")
    /// Leave note
    internal static let questLeaveNewNoteYes = L10n.tr("Localizable", "quest_leave_new_note_yes", fallback: "Leave note")
    /// Is there lighting along this sidewalk at night?
    internal static let questLitTitle = L10n.tr("Localizable", "quest_lit_title", fallback: "Is there lighting along this sidewalk at night?")
    /// Does this pedestrian crossing have an island?
    internal static let questPedestrianCrossingIsland = L10n.tr("Localizable", "quest_pedestrian_crossing_island", fallback: "Does this pedestrian crossing have an island?")
    /// Roadway width from curb to curb includes on-street parking and bicycle lanes but excludes sidewalks, off-street parking, or adjacent bicycle paths.
    internal static let questRoadWidthExplanation = L10n.tr("Localizable", "quest_road_width_explanation", fallback: "Roadway width from curb to curb includes on-street parking and bicycle lanes but excludes sidewalks, off-street parking, or adjacent bicycle paths.")
    /// This width seems unlikely. Just remember, it should account for everything from one side of the road to the other, like parking spaces and bike lanes.
    internal static let questRoadWidthUnusualInputConfirmationDescription = L10n.tr("Localizable", "quest_road_width_unusualInput_confirmation_description", fallback: "This width seems unlikely. Just remember, it should account for everything from one side of the road to the other, like parking spaces and bike lanes.")
    /// What surface does this footpath have here?
    internal static let questSidewalkSurfaceTitle = L10n.tr("Localizable", "quest_sidewalk_surface_title", fallback: "What surface does this footpath have here?")
    /// Does this street have a sidewalk?
    internal static let questSidewalkTitle = L10n.tr("Localizable", "quest_sidewalk_title", fallback: "Does this street have a sidewalk?")
    /// sidewalk on both the sides
    internal static let questSidewalkValueBoth = L10n.tr("Localizable", "quest_sidewalk_value_both", fallback: "sidewalk on both the sides")
    /// sidewalk on the left
    internal static let questSidewalkValueLeft = L10n.tr("Localizable", "quest_sidewalk_value_left", fallback: "sidewalk on the left")
    /// no sidewalk
    internal static let questSidewalkValueNo = L10n.tr("Localizable", "quest_sidewalk_value_no", fallback: "no sidewalk")
    /// No sidewalk at all
    internal static let questSidewalkValueNoSidewalkAtAll = L10n.tr("Localizable", "quest_sidewalk_value_no_sidewalk_at_all", fallback: "No sidewalk at all")
    /// sidewalk on the right
    internal static let questSidewalkValueRight = L10n.tr("Localizable", "quest_sidewalk_value_right", fallback: "sidewalk on the right")
    /// sidewalk, but displayed separately on map
    internal static let questSidewalkValueSeparate = L10n.tr("Localizable", "quest_sidewalk_value_separate", fallback: "sidewalk, but displayed separately on map")
    /// Only information that was verified in-person should be entered.
    internal static let questSourceDialogNote = L10n.tr("Localizable", "quest_source_dialog_note", fallback: "Only information that was verified in-person should be entered.")
    /// Are you sure you checked this on-site?
    internal static let questSourceDialogTitle = L10n.tr("Localizable", "quest_source_dialog_title", fallback: "Are you sure you checked this on-site?")
    /// Specify whether steps have handrails
    internal static let questSpecifyHandrails = L10n.tr("Localizable", "quest_specify_handrails", fallback: "Specify whether steps have handrails")
    /// How many flights of stairs are available?
    internal static let questStairFlights = L10n.tr("Localizable", "quest_stair_flights", fallback: "How many flights of stairs are available?")
    /// Just the number of steps to reach the top. If the step count differs on each side, give the higher number.
    internal static let questStepCountStileHint = L10n.tr("Localizable", "quest_step_count_stile_hint", fallback: "Just the number of steps to reach the top. If the step count differs on each side, give the higher number.")
    /// How many steps are in this staircase?
    internal static let questStepCountTitle = L10n.tr("Localizable", "quest_step_count_title", fallback: "How many steps are in this staircase?")
    /// Which direction leads upwards for these steps?
    internal static let questStepsInclineTitle = L10n.tr("Localizable", "quest_steps_incline_title", fallback: "Which direction leads upwards for these steps?")
    /// This way up
    internal static let questStepsInclineUp = L10n.tr("Localizable", "quest_steps_incline_up", fallback: "This way up")
    /// Bicycle ramp
    internal static let questStepsRampBicycle = L10n.tr("Localizable", "quest_steps_ramp_bicycle", fallback: "Bicycle ramp")
    /// No (usable) ramp
    internal static let questStepsRampNone = L10n.tr("Localizable", "quest_steps_ramp_none", fallback: "No (usable) ramp")
    /// Is the wheelchair ramp displayed as a separate way on the map?
    internal static let questStepsRampSeparateWheelchair = L10n.tr("Localizable", "quest_steps_ramp_separate_wheelchair", fallback: "Is the wheelchair ramp displayed as a separate way on the map?")
    /// separate
    internal static let questStepsRampSeparateWheelchairConfirm = L10n.tr("Localizable", "quest_steps_ramp_separate_wheelchair_confirm", fallback: "separate")
    /// not separate
    internal static let questStepsRampSeparateWheelchairDecline = L10n.tr("Localizable", "quest_steps_ramp_separate_wheelchair_decline", fallback: "not separate")
    /// Stroller ramp
    internal static let questStepsRampStroller = L10n.tr("Localizable", "quest_steps_ramp_stroller", fallback: "Stroller ramp")
    /// Do these steps have a ramp? What kind?
    internal static let questStepsRampTitle = L10n.tr("Localizable", "quest_steps_ramp_title", fallback: "Do these steps have a ramp? What kind?")
    /// Wheelchair ramp
    internal static let questStepsRampWheelchair = L10n.tr("Localizable", "quest_steps_ramp_wheelchair", fallback: "Wheelchair ramp")
    /// Artificial turf
    internal static let questSurfaceValueArtificialTurf = L10n.tr("Localizable", "quest_surface_value_artificial_turf", fallback: "Artificial turf")
    /// Asphalt
    internal static let questSurfaceValueAsphalt = L10n.tr("Localizable", "quest_surface_value_asphalt", fallback: "Asphalt")
    /// Clay
    internal static let questSurfaceValueClay = L10n.tr("Localizable", "quest_surface_value_clay", fallback: "Clay")
    /// Compacted
    internal static let questSurfaceValueCompacted = L10n.tr("Localizable", "quest_surface_value_compacted", fallback: "Compacted")
    /// Concrete
    internal static let questSurfaceValueConcrete = L10n.tr("Localizable", "quest_surface_value_concrete", fallback: "Concrete")
    /// Concrete lanes
    internal static let questSurfaceValueConcreteLanes = L10n.tr("Localizable", "quest_surface_value_concrete_lanes", fallback: "Concrete lanes")
    /// Concrete plates
    internal static let questSurfaceValueConcretePlates = L10n.tr("Localizable", "quest_surface_value_concrete_plates", fallback: "Concrete plates")
    /// Dirt
    internal static let questSurfaceValueDirt = L10n.tr("Localizable", "quest_surface_value_dirt", fallback: "Dirt")
    /// Fine gravel
    internal static let questSurfaceValueFineGravel = L10n.tr("Localizable", "quest_surface_value_fine_gravel", fallback: "Fine gravel")
    /// Grass
    internal static let questSurfaceValueGrass = L10n.tr("Localizable", "quest_surface_value_grass", fallback: "Grass")
    /// Grass paver
    internal static let questSurfaceValueGrassPaver = L10n.tr("Localizable", "quest_surface_value_grass_paver", fallback: "Grass paver")
    /// Gravel
    internal static let questSurfaceValueGravel = L10n.tr("Localizable", "quest_surface_value_gravel", fallback: "Gravel")
    /// Ground (generic)
    internal static let questSurfaceValueGround = L10n.tr("Localizable", "quest_surface_value_ground", fallback: "Ground (generic)")
    /// Metal
    internal static let questSurfaceValueMetal = L10n.tr("Localizable", "quest_surface_value_metal", fallback: "Metal")
    /// Persistent mud
    internal static let questSurfaceValueMud = L10n.tr("Localizable", "quest_surface_value_mud", fallback: "Persistent mud")
    /// Paved (generic)
    internal static let questSurfaceValuePaved = L10n.tr("Localizable", "quest_surface_value_paved", fallback: "Paved (generic)")
    /// Paving stones
    internal static let questSurfaceValuePavingStones = L10n.tr("Localizable", "quest_surface_value_paving_stones", fallback: "Paving stones")
    /// Pebbles
    internal static let questSurfaceValuePebblestone = L10n.tr("Localizable", "quest_surface_value_pebblestone", fallback: "Pebbles")
    /// Rock
    internal static let questSurfaceValueRock = L10n.tr("Localizable", "quest_surface_value_rock", fallback: "Rock")
    /// Sand
    internal static let questSurfaceValueSand = L10n.tr("Localizable", "quest_surface_value_sand", fallback: "Sand")
    /// Sett
    internal static let questSurfaceValueSett = L10n.tr("Localizable", "quest_surface_value_sett", fallback: "Sett")
    /// Tartan
    internal static let questSurfaceValueTartan = L10n.tr("Localizable", "quest_surface_value_tartan", fallback: "Tartan")
    /// Unhewn cobblestone
    internal static let questSurfaceValueUnhewnCobblestone = L10n.tr("Localizable", "quest_surface_value_unhewn_cobblestone", fallback: "Unhewn cobblestone")
    /// Unpaved (generic)
    internal static let questSurfaceValueUnpaved = L10n.tr("Localizable", "quest_surface_value_unpaved", fallback: "Unpaved (generic)")
    /// Wood
    internal static let questSurfaceValueWood = L10n.tr("Localizable", "quest_surface_value_wood", fallback: "Wood")
    /// Woodchips
    internal static let questSurfaceValueWoodchips = L10n.tr("Localizable", "quest_surface_value_woodchips", fallback: "Woodchips")
    /// Is there tactile paving on this curb here?
    internal static let questTactilePavingKerbTitle = L10n.tr("Localizable", "quest_tactile_paving_kerb_title", fallback: "Is there tactile paving on this curb here?")
    /// Does this crosswalk have tactile paving on both ends?
    internal static let questTactilePavingCrosswalk = L10n.tr("Localizable", "quest_tactilePaving_crosswalk", fallback: "Does this crosswalk have tactile paving on both ends?")
    /// Is there tactile paving at the top and bottom of these steps?
    internal static let questTactilePavingTitleSteps = L10n.tr("Localizable", "quest_tactilePaving_title_steps", fallback: "Is there tactile paving at the top and bottom of these steps?")
    /// Localizable.strings
    ///   GoInfoGame
    /// 
    ///   Created by Lakshmi Shweta Pochiraju on 09/01/24.
    internal static let questWidthMostNarrowPath = L10n.tr("Localizable", "quest_width_most_narrow_path", fallback: "What is the width of the most narrow usable path along this footpath? (measure with your phone please)")
    /// Questions List
    internal static let questionsList = L10n.tr("Localizable", "questions_list", fallback: "Questions List")
    /// Refresh list
    internal static let refreshList = L10n.tr("Localizable", "Refresh list", fallback: "Refresh list")
    /// Revert Changes
    internal static let revertChanges = L10n.tr("Localizable", "Revert Changes", fallback: "Revert Changes")
    /// Select:
    internal static let select = L10n.tr("Localizable", "Select", fallback: "Select:")
    /// Select the quest based on date and time for preview & revert
    internal static let selectTheQuestBasedOnDateAndTimeForPreviewRevert = L10n.tr("Localizable", "Select the quest based on date and time for preview & revert", fallback: "Select the quest based on date and time for preview & revert")
    /// Select the quest to start answering.
    internal static let selectTheQuestToStartAnswering = L10n.tr("Localizable", "Select the quest to start answering.", fallback: "Select the quest to start answering.")
    /// Select One:
    internal static let selectOne = L10n.tr("Localizable", "select_one", fallback: "Select One:")
    /// Selected Type:
    internal static let selectedType = L10n.tr("Localizable", "Selected Type:", fallback: "Selected Type:")
    /// Start answering the questions
    internal static let startAnsweringTheQuestions = L10n.tr("Localizable", "Start answering the questions", fallback: "Start answering the questions")
    /// Type
    internal static let type = L10n.tr("Localizable", "Type", fallback: "Type")
    /// Undo Edits
    internal static let undoEdits = L10n.tr("Localizable", "Undo Edits", fallback: "Undo Edits")
    /// Undo the following changes?
    internal static let undoTheFollowingChanges = L10n.tr("Localizable", "Undo the following changes?", fallback: "Undo the following changes?")
    /// Undo your recent changes
    internal static let undoYourRecentChanges = L10n.tr("Localizable", "Undo your recent changes", fallback: "Undo your recent changes")
    /// Cancel
    internal static let undoConfirmNegative = L10n.tr("Localizable", "undo_confirm_negative", fallback: "Cancel")
    /// Update
    internal static let update = L10n.tr("Localizable", "Update", fallback: "Update")
    /// Update Available
    internal static let updateAvailable = L10n.tr("Localizable", "Update Available", fallback: "Update Available")
    /// Update Required
    internal static let updateRequired = L10n.tr("Localizable", "Update Required", fallback: "Update Required")
    /// Usually looks like this?
    internal static let usuallyLooksLikeThis = L10n.tr("Localizable", "usually_looks_like_this", fallback: "Usually looks like this?")
    /// Workspace
    internal static let workspace = L10n.tr("Localizable", "Workspace", fallback: "Workspace")
    /// You’ve arrived at the quest location!
    internal static let youVeArrivedAtTheQuestLocation = L10n.tr("Localizable", "You’ve arrived at the quest location!", fallback: "You’ve arrived at the quest location!")
    /// You’ve Arrived!
    internal static let youVeArrived = L10n.tr("Localizable", "You’ve Arrived!", fallback: "You’ve Arrived!")
    internal enum ANewVersionOfTheAppIsAvailable {
      /// A new version of the app is available. Please update to continue using the app.
      internal static let pleaseUpdateToContinueUsingTheApp = L10n.tr("Localizable", "A new version of the app is available. Please update to continue using the app.", fallback: "A new version of the app is available. Please update to continue using the app.")
      /// A new version of the app is available. Would you like to update now?
      internal static let wouldYouLikeToUpdateNow = L10n.tr("Localizable", "A new version of the app is available. Would you like to update now?", fallback: "A new version of the app is available. Would you like to update now?")
    }
  }
  internal enum Main {
    internal enum _13PWzT0e {
      /// Class = "UIButton"; normalTitle = "Button"; ObjectID = "13P-wz-T0e";
      internal static let normalTitle = L10n.tr("Main", "13P-wz-T0e.normalTitle", fallback: "Button")
      internal enum Configuration {
        /// Class = "UIButton"; configuration.title = "View Quests"; ObjectID = "13P-wz-T0e";
        internal static let title = L10n.tr("Main", "13P-wz-T0e.configuration.title", fallback: "View Quests")
      }
    }
    internal enum GjVBOUiV {
      /// Class = "UIButton"; normalTitle = "Button"; ObjectID = "gjV-BO-UiV";
      internal static let normalTitle = L10n.tr("Main", "gjV-BO-UiV.normalTitle", fallback: "Button")
      internal enum Configuration {
        /// Class = "UIButton"; configuration.title = "Login"; ObjectID = "gjV-BO-UiV";
        internal static let title = L10n.tr("Main", "gjV-BO-UiV.configuration.title", fallback: "Login")
      }
    }
    internal enum QAsAPWC6 {
      /// Class = "UIButton"; normalTitle = "Button"; ObjectID = "qAs-AP-wC6";
      internal static let normalTitle = L10n.tr("Main", "qAs-AP-wC6.normalTitle", fallback: "Button")
      internal enum Configuration {
        /// Class = "UIButton"; configuration.title = "Skip"; ObjectID = "qAs-AP-wC6";
        internal static let title = L10n.tr("Main", "qAs-AP-wC6.configuration.title", fallback: "Skip")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
