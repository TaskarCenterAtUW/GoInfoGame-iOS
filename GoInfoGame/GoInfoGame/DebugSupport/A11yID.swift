//
//  A11yID.swift
//  GoInfoGame
//
//  Accessibility identifiers and UI-test scenario names shared between the app and the
//  UI test target.
//
//  This file is a member of BOTH GoInfoGame and GoInfoGameUITests on purpose: the app
//  sets these on its views, the tests query by them, and because both sides reference
//  the same constant a rename breaks the build instead of silently turning into a test
//  that can never find its element.
//
//  Identifiers are deliberately NOT localized and NOT derived from visible text -
//  `.accessibilityLabel` is what the user hears and it changes per locale (this app
//  ships en and fr), so tests must never match on it to locate an element.
//

import Foundation

enum A11yID {

    enum Login {
        static let usernameField = "login_username_field"
        static let passwordField = "login_password_field"
        static let passwordVisibilityToggle = "login_password_visibility_toggle"
        static let loginButton = "login_submit_button"
        static let errorMessage = "login_error_message"
        static let environmentPicker = "login_environment_picker"
        static let forgotPasswordButton = "login_forgot_password_button"
        static let biometricButton = "login_biometric_button"
        static let scrollView = "login_scroll_view"
        static let newUserButton = "login_new_user_button"
        static let contactUsButton = "login_contact_us_button"
        static let accessMapButton = "login_access_map_button"
        static let loadingIndicator = "login_loading_indicator"
        static let appVersionLabel = "login_app_version_label"
        static let exitDebugModeButton = "login_exit_debug_mode_button"
        /// Test-only element (see PosmLogin.swift) that reaches the same state as 7 real
        /// taps on `appVersionLabel`, since XCUITest cannot reliably drive that native
        /// multi-tap gesture. Only exists when UITestRuntime.isActive; invisible and
        /// absent otherwise, including in ordinary manual DEBUG-build use.
        static let debugModeUITestUnlock = "login_debug_mode_uitest_unlock"
    }

    enum Workspaces {
        static let title = "workspaces_title"
        static let profileButton = "workspaces_profile_button"
        static let searchToggleButton = "workspaces_search_toggle_button"
        static let searchField = "workspaces_search_field"
        static let searchClearButton = "workspaces_search_clear_button"
        static let projectGroupFilter = "workspaces_project_group_filter"
        static let clearFiltersButton = "workspaces_clear_filters_button"
        static let tryAgainButton = "workspaces_try_again_button"
        static let loadingText = "workspaces_loading_text"
        static let errorText = "workspaces_error_text"
        static let emptyText = "workspaces_empty_text"
        static let noResultsText = "workspaces_no_results_text"
        static let scrollView = "workspaces_scroll_view"

        /// Identifier for one workspace's row button in the list. Built from the
        /// workspace's own numeric id (matching a mock fixture's "id" field) rather than
        /// its title, so a test can address a specific row without depending on wording
        /// that might be localized or renamed later.
        static func workspaceRow(id: Int) -> String {
            "workspaces_row_\(id)"
        }
    }

    enum Profile {
        static let scrollView = "profile_scroll_view"
        static let backButton = "profile_back_button"
        static let titleLabel = "profile_title_label"
        /// One combined element (UserProfileView already applies
        /// .accessibilityElement(children: .combine) to the name+email VStack), so a
        /// single identifier covers both rather than one each.
        static let nameAndEmailLabel = "profile_name_and_email_label"
        static let lowBandwidthToggle = "profile_low_bandwidth_toggle"
        /// Only exists when BiometricAuthManager.canEvaluateBiometrics() is true, i.e. the
        /// simulator has Face ID/Touch ID enrolled - not the case on a fresh/CI simulator
        /// by default, unlike location this cannot be pre-configured via `xcrun simctl`.
        /// Tests must treat its absence as valid, not as a failure.
        static let biometricToggle = "profile_biometric_toggle"
        static let logoutButton = "profile_logout_button"
    }

    /// Identifiers for the LongForm quest-answer form (GoInfoGame/quests/LongQuests) and
    /// the sheet that hosts it (MapView.swift's QuestSheetView).
    ///
    /// Two constraints learned from the real accessibility hierarchy, that shape this set:
    /// - identifiers go on LEAF controls only. Putting one on a container with several
    ///   independent children stamps the same value onto every leaf inside it - confirmed
    ///   directly for QuestSheetView's own root Group (see MapView.swift), which is why
    ///   it has no identifier of its own and the dismiss button below is used instead.
    /// - choice tiles are `.accessibilityElement(children: .combine)` buttons whose LABEL
    ///   already carries the selection state ("<choice> option selected" / "... option
    ///   unselected"), so state is asserted through the label; the identifier only locates.
    enum LongForm {
        /// The pinned header's close ("X") button, label "Dismiss". Doubles as the
        /// "form is open" signal (the sheet has no other stable root element).
        static let dismissButton = "longform_dismiss_button"
        /// The List holding everything below the header - the scroll container for every
        /// reachability / "scroll until visible" check.
        static let scrollView = "longform_scroll_view"
        static let composeNoteButton = "longform_compose_note_button"
        static let ignoreQuestButton = "longform_ignore_quest_button"
        static let submitButton = "longform_submit_button"

        /// One tile of an ExclusiveChoice/MultipleChoice question:
        /// `longform_option_<questID>_<choice value>` (e.g. `longform_option_101_concrete`).
        static func option(questID: Int, value: String) -> String { "longform_option_\(questID)_\(value)" }
        /// The free-text (TextEntry) input of a question: `longform_text_<questID>`.
        static func textInput(questID: Int) -> String { "longform_text_\(questID)" }
        /// The Numeric input of a question: `longform_numeric_<questID>`.
        static func numericInput(questID: Int) -> String { "longform_numeric_\(questID)" }
        /// The question's title text: `longform_question_<questID>` - lets a test assert a
        /// dependent question appeared/disappeared without depending on its wording.
        static func question(questID: Int) -> String { "longform_question_\(questID)" }
        /// QuestSheetView's "This element has already been answered by another user"
        /// state - shown instead of the form when the freshness fetch reveals someone
        /// else already completed every applicable question.
        static let alreadyAnsweredMessage = "longform_already_answered_message"
        static let alreadyAnsweredOKButton = "longform_already_answered_ok_button"
    }

    /// Identifiers for the Accessibility (Screen Reader) Mode screen (GoInfoGame/UI/Map/
    /// Accessibility Mode/), reached from A11yID.Map.accessibilityModeButton. Same two
    /// constraints as A11yID.LongForm apply here (leaf-only identifiers; state read
    /// through the label, not the identifier) - see that enum's own comment.
    enum AccessibilityMode {
        /// The List holding the quest-count header, the nearest-quest cards, and the
        /// bottom bar (undo/go-to-map) - the scroll container for every reachability /
        /// "scroll until visible" check. Only rendered when viewModel.nearestQuest is
        /// non-empty; see noQuestsMessage for the alternative branch.
        static let scrollView = "accessibility_mode_scroll_view"
        /// "Showing N quest(s)" header - lets a test assert the count shown to the user
        /// matches how many cards are actually in the list, without depending on wording.
        static let questCountLabel = "accessibility_mode_quest_count_label"
        static let refreshButton = "accessibility_mode_refresh_button"
        /// Opens ManageQuestsView (the "tune" toolbar icon) - out of scope for this
        /// suite's own tests (it's ManageQuestsView's own screen to test), identified
        /// here only so a bounds/overlap/reachability check can include it.
        static let filterButton = "accessibility_mode_filter_button"
        static let undoEditButton = "accessibility_mode_undo_edit_button"
        static let goToMapButton = "accessibility_mode_go_to_map_button"
        /// NoQuestsNearView's "No quests found" text - shown in place of the List when
        /// nearestQuest is empty. Doubles as that state's presence signal.
        static let noQuestsMessage = "accessibility_mode_no_quests_message"

        /// One row of the nearest-quest list: `accessibility_mode_quest_card_<elementID>`
        /// - the underlying OSM element id (DisplayUnitWithCoordinate.id), the same
        /// identity A11yID.Map.questAnnotation's own accessibilityValue and A11yID
        /// .LongForm's per-question identifiers use, so a test can target one specific
        /// card regardless of where the distance sort puts it.
        static func questCard(elementID: Int64) -> String { "accessibility_mode_quest_card_\(elementID)" }

        // QuestSelectionConfirmationView - the sheet shown after tapping a quest card,
        // before LongForm. No root identifier of its own - same reasoning as
        // A11yID.Map.pinChoiceCreateNoteButton (a multi-child container stamps one
        // identifier onto every leaf) - startAnswerButton doubles as this sheet's
        // presence signal.
        static let confirmationAnswerButton = "accessibility_mode_confirmation_answer_button"
        static let confirmationHideButton = "accessibility_mode_confirmation_hide_button"
        static let confirmationNotNowButton = "accessibility_mode_confirmation_not_now_button"
    }

    enum Map {
        // MARK: Top bar
        static let profileButton = "map_profile_button"
        /// The tappable workspace-name element in the toolbar (name + "Workspace" label
        /// combined into one accessibility element; tapping it shows a change-workspace
        /// confirmation alert, matched by its title text like every other alert in this
        /// app).
        static let workspaceTitleButton = "map_workspace_title_button"
        static let syncButton = "map_sync_button"
        static let accessibilityModeButton = "map_accessibility_mode_button"
        static let manageQuestsButton = "map_manage_quests_button"

        // MARK: Floating buttons
        static let layersButton = "map_layers_button"
        static let downloadButton = "map_download_button"
        static let undoButton = "map_undo_button"
        /// Only rendered once the map is rotated off north (CompassButtonView's own
        /// condition) - simulating a rotation gesture reliably via XCUITest is not
        /// something this suite attempts, so treat this the same as the Profile screen's
        /// biometric toggle: absence is not itself a failure.
        static let compassButton = "map_compass_button"
        static let zoomInButton = "map_zoom_in_button"
        static let zoomOutButton = "map_zoom_out_button"
        static let myLocationButton = "map_my_location_button"
        static let scaleBar = "map_scale_bar"

        // MARK: Map annotations
        //
        // QuestAnnotationView/QuestClusterAnnotationView are raw MLNAnnotationView
        // (UIKit) subclasses drawn directly on the MLNMapView, not SwiftUI - but
        // accessibilityIdentifier is a UIView/UIAccessibilityIdentification property, so
        // it applies here the same way. Both use ONE shared identifier (there can be
        // several on screen at once, each a distinct element XCUITest enumerates
        // separately) rather than one per instance, since which quest/cluster renders
        // where is data-dependent. A cluster's count is readable via its accessibility
        // value/label - see QuestClusterAnnotationView. A quest pin's own accessibility
        // value likewise carries its underlying OSM element's id - not set directly on
        // QuestAnnotationView, but via LongElementQuest.displayUnit's `description`
        // (confirmed directly: MapLibre auto-copies DisplayUnitAnnotation.subtitle,
        // which reads that field, into the rendered annotation view's own
        // accessibilityValue, overwriting anything set explicitly on the UIView itself)
        // - see that property's own comment.
        static let questAnnotation = "map_quest_annotation"
        static let clusterAnnotation = "map_cluster_annotation"

        // MARK: Actions & flows - identifiers on what each button/gesture opens, so a
        // test can confirm the transition happened, not just that the trigger exists.
        //
        // QuestSheetView (presented after tapping a quest/cluster annotation) has no
        // root identifier of its own - see A11yID.LongForm's own comment for why - use
        // A11yID.LongForm.dismissButton / .alreadyAnsweredOKButton as the "did it open"
        // signal instead.
        /// The small "Create Note"/"Add Feature" card shown after a long-press on empty
        /// map area (MapView.swift's PinChoiceCard) has no root identifier of its own -
        /// confirmed directly that giving a multi-child container like it one stamps
        /// that identifier onto every leaf inside, overwriting these two buttons' own.
        /// "Create Note" existing doubles as the card's presence signal for tests.
        static let pinChoiceCreateNoteButton = "map_pin_choice_create_note_button"
        static let pinChoiceAddFeatureButton = "map_pin_choice_add_feature_button"
        /// Root of the bottom sheet shown after a long-press directly on a quest
        /// annotation (MapView.swift's MultiQuestSelectionBottomSheet).
        static let multiSelectSheet = "map_multi_select_sheet"
        /// The transient "No elements to sync" (or other status) overlay shown after
        /// tapping the sync button - MapView.swift's own showAlert/alertMessage state,
        /// not a system alert. Shared across whatever alertMessage happens to be set.
        static let syncStatusAlert = "map_sync_status_alert"
        /// UndoSidebarView's close button - no root identifier on the sidebar itself,
        /// same reasoning as pinChoiceCreateNoteButton above. Doubles as the sidebar's
        /// presence signal for tests.
        static let undoSidebarCloseButton = "map_undo_sidebar_close_button"
        /// AccessibilityModeView's close ("X") button - also doubles as this screen's
        /// presence signal, since the screen itself has no root identifier.
        static let accessibilityModeCloseButton = "map_accessibility_mode_close_button"
        /// ManageQuestsView's close ("X") button - same role as accessibilityModeCloseButton.
        static let manageQuestsCloseButton = "map_manage_quests_close_button"
    }
}

/// Names of the stubbed network scenarios a UI test can launch the app under.
///
/// Shared for the same reason as the identifiers above: the app switches on these in
/// `UITestStubs` and the tests pass them to `launchApp(scenario:)`. `UITestStubs` itself
/// is app-target-only and DEBUG-gated, so it cannot be the home for them - a bare string
/// on the test side would mean a typo produces a run with only the catch-all installed
/// (every request failing) instead of a compile error.
enum UITestScenario {
    /// Launch-environment key the UI tests set to pick a scenario; the app reads it in
    /// UITestStubs.installIfNeeded(). Centralized here (rather than duplicated as a raw
    /// string on both sides) so a typo on either end is a compile error.
    static let environmentKey = "UITEST_SCENARIO"

    static let loginInvalidCredentials = "login_invalid_credentials"
    static let loginSuccess = "login_success"
    static let loginServerError = "login_server_error"
    static let loginNetworkDown = "login_network_down"
    static let loginSlowResponse = "login_slow_response"
    /// Seeds Keychain credentials + the biometric-enabled flag for .production (the
    /// screen's default selectedEnvironment) instead of the usual force-declined state,
    /// so the biometric login button actually renders and can be asserted on.
    static let loginBiometricAvailable = "login_biometric_available"

    /// Rich workspace list (multiple entries across 2 project groups) - backs search,
    /// filter, scroll/overlap and profile-navigation tests. Deliberately more than 1
    /// eligible workspace: exactly 1 makes the screen skip the list UI entirely and
    /// auto-navigate to the map (see `workspacesSingleAutoRedirect`).
    static let workspacesWithData = "workspaces_with_data"
    /// Zero workspaces returned for an otherwise-successful login.
    static let workspacesEmpty = "workspaces_empty"
    /// The workspaces fetch itself fails with a 500.
    static let workspacesServerError = "workspaces_server_error"
    /// The workspaces fetch fails as a connectivity error, not an HTTP error - same UI
    /// branch as workspacesServerError today (there is no dedicated offline state), kept
    /// as its own scenario so the test's intent (network, not server) stays explicit.
    static let workspacesNetworkDown = "workspaces_network_down"
    /// Exactly 1 eligible workspace: WorkspacesListView skips the picker UI and
    /// auto-navigates straight to MapView once the workspace's details (including an
    /// empty-but-valid longFormQuestDef) resolve.
    static let workspacesSingleAutoRedirect = "workspaces_single_auto_redirect"

    /// The Profile screen's success path is already covered by workspacesWithData (it
    /// stubs GET /user-profile -> UserProfilePlaceholder alongside the workspaces list),
    /// so it does not need its own scenario. This one is for the failure path only:
    /// UserProfileView has no error UI branch for a failed profile fetch - name/email
    /// stay blank while everything else (toggles, logout, back) stays usable, which is
    /// what this scenario is for verifying.
    static let profileFetchError = "profile_fetch_error"

    /// Reaches MapView: a single eligible workspace (id 3001, distinct from
    /// workspacesSingleAutoRedirect's id 222 so the two scenarios' fixtures never
    /// collide) whose details response has a genuinely populated longFormQuestDef -
    /// adapted from GoInfoGame/Helpers/SampleResponses/LongQuestsResponse.json, a real
    /// captured response already in this repo, trimmed to one quest_query ("nodes with
    /// (ext:junction=yes)") - plus a /map.json OSM elements response (also modeled on
    /// the real SCLIO Seattle pins response.json already in this repo, trimmed to a
    /// handful of nodes) with 5 matching nodes placed a few meters apart (expected to
    /// cluster) and 1 more several km away (expected to stay a separate pin).
    static let mapWithQuestClusters = "map_with_quest_clusters"

    /// Multiple eligible workspaces (the same list as workspacesWithData) where tapping a
    /// row succeeds: `GET /workspaces/{id}` resolves to WorkspaceDetailsWithQuests and
    /// `map.json` to MapOSMElements, so the real picker -> fetchLongQuestsFor -> MapView
    /// path runs. Unlike mapWithQuestClusters (1 eligible workspace, auto-redirect), this
    /// is what lets a test go Workspaces -> Map and back again via "change workspace".
    static let workspacesPickRowToMap = "workspaces_pick_row_to_map"
    /// Same list, but `GET /workspaces/{id}` fails with a 500, exercising the alert
    /// InitialView shows when a tapped workspace's details cannot be loaded.
    static let workspacesPickRowDetailsError = "workspaces_pick_row_details_error"
    /// Same list, but `GET /workspaces/{id}` answers 401 and the follow-up refresh-token
    /// request fails too - the app's real "session expired" path: it swaps the root view
    /// back to the login screen and posts SessionExpired, which shows the "Logout" alert.
    static let sessionExpiredOnWorkspaceDetails = "session_expired_on_workspace_details"
    /// A successful login on a device where biometrics are available and not yet
    /// declined, so the "Enable Biometric Login?" prompt shows after login. Also forces
    /// BiometricAuthManager.canEvaluateBiometrics() to true for this scenario only - the
    /// simulator's real enrollment state differs between machines (see
    /// UITestStubs.resetStateIfNeeded()) and cannot be relied on.
    static let loginBiometricPrompt = "login_biometric_prompt"

    /// PLACEHOLDERS for the LongForm suite (stubs not written yet - an unknown scenario
    /// only installs the catch-all). All three land on the Map with LongFormOSMElements
    /// .json (5 tappable pins, 1 fully-answered way that must show no pin) and
    /// WorkspaceDetailsWithQuests.json's quest definitions.
    ///
    /// Everything on the OSM API succeeds: freshness fetch (LongFormLatestElements.json),
    /// then changeset create -> upload -> close.
    static let longFormOnline = "long_form_online"
    /// The map data loads, but every OSM API call after that fails with a connectivity
    /// error (fetch on tap, changeset create/upload/close) - a mid-session outage.
    static let longFormNetworkDown = "long_form_network_down"
    /// Like longFormNetworkDown for the FIRST changeset attempt only, then everything
    /// succeeds - so a Submit queues offline and the Sync button's retry goes through.
    static let longFormNetworkRecovers = "long_form_network_recovers"

    /// PLACEHOLDERS for the Accessibility (Screen Reader) Mode suite. All three land on
    /// the Map the same way the longForm* scenarios do (real Workspaces auto-redirect),
    /// but serve AccessibilityModeOSMElements.json - a fixture engineered around known
    /// distances/bearings from the fixed UI-test camera rather than around tags, since
    /// AccessibilityModeViewModel's own logic (filterQuestsNerestToUser) is purely
    /// geometric. See that fixture's own "_note" for exactly what each element is.
    static let accessibilityModeOnline = "accessibility_mode_online"
    /// Same map data, but every OSM API call after the map load fails with a
    /// connectivity error - proves the nearest-quest list (a pure local-DB read via
    /// mapViewModel.items) is unaffected by network state, since
    /// AccessibilityModeViewModel itself never calls the network at all.
    static let accessibilityModeNetworkDown = "accessibility_mode_network_down"
    /// AccessibilityModeOSMElementsFar.json - every element sits well beyond the 250m
    /// distanceThreshold, so viewModel.nearestQuest ends up empty and NoQuestsNearView
    /// renders.
    static let accessibilityModeNoNearbyQuests = "accessibility_mode_no_nearby_quests"

    /// Launch argument (not environment) that clears UserDefaults and the Keychain.
    static let resetStateArgument = "-UITestResetState"
}

/// True only when the app was launched by a UI test (any UITEST_SCENARIO value set).
/// Always safe to check in Release too - the key is never present outside a test launch.
enum UITestRuntime {
    static var isActive: Bool {
        ProcessInfo.processInfo.environment[UITestScenario.environmentKey] != nil
    }
}
