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
