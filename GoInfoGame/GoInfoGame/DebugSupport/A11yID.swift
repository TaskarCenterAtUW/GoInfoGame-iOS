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
        // value/label - see QuestClusterAnnotationView.
        static let questAnnotation = "map_quest_annotation"
        static let clusterAnnotation = "map_cluster_annotation"

        // MARK: Actions & flows - identifiers on what each button/gesture opens, so a
        // test can confirm the transition happened, not just that the trigger exists.
        /// Root of the quest-answer sheet (MapView.swift's QuestSheetView) - presented
        /// after tapping a quest/cluster annotation. Covers only "did it open", not its
        /// per-quest-type form content, which has no identifiers of its own.
        static let questAnswerSheet = "map_quest_answer_sheet"
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
