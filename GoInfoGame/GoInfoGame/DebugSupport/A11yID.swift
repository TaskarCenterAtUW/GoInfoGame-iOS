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
