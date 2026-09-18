//
//  PosmLogin.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import SwiftUI
import LocalAuthentication

struct PosmLoginView: View {
    
    @ObservedObject var viewModel = PosmLoginViewModel()
    
    @State private var isShowingAlert = false
    @State private var shouldLogin = false
    
    @State private var selectedEnvironment: APIEnvironment = .production
    @State private var showAlert = false
    @State private var debugMode: Bool = false
    @State private var showEnableDebugModeAlert: Bool = false
    @State private var showDisableDebugModeAlert: Bool = false
    let forceUpdateManager: ForceUpdateManager?
    
    init(forceUpdateManager: ForceUpdateManager?) {
        self.forceUpdateManager = forceUpdateManager
    }
            
    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geometry in
                    let scrollView = ScrollView {
                        loginContent
                            .padding([.top], 0)
                            .frame(minHeight: geometry.size.height)
                    }
                    if #available(iOS 16.4, *) {
                        scrollView
                            .scrollBounceBehavior(.basedOnSize)
                            .accessibilityIdentifier(A11yID.Login.scrollView)
                    } else {
                        scrollView
                            .accessibilityIdentifier(A11yID.Login.scrollView)
                    }
                }

                if viewModel.isLoading {
                    ActivityView(activityText: "Loading...")
                        .accessibilityIdentifier(A11yID.Login.loadingIndicator)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationDestination(isPresented: $viewModel.isLoginSuccess) {
                InitialView()
            }
        }
        .alert(viewModel.errorMessage ?? "Invalid Credentials", isPresented: $viewModel.shouldShowValidationAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Enable Biometric Login?", isPresented: $viewModel.showBiometricPrompt) {
            Button("Enable") {
                viewModel.enableBiometrics(enable: true)
            }
            Button("Not Now", role: .cancel) {
                viewModel.enableBiometrics(enable: false)
            }
        } message: {
            Text("Would you like to use Face ID or Touch ID for faster logins?")
        }
        .alert("Debug mode", isPresented: $showEnableDebugModeAlert) {
            Button("Enable") {
                debugMode = true
            }
            Button("Not Now", role: .cancel) {

            }
        } message: {
            Text("Do you want to enable debug mode?")
        }
        .alert("Debug mode", isPresented: $showDisableDebugModeAlert) {
            Button("Disable") {
                selectedEnvironment = .production
                debugMode = false
            }
            Button("Not Now", role: .cancel) {

            }
        } message: {
            Text("Do you want to disable debug mode?")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SessionExpired"))) { notification in
                    showAlert = true
                }
                .alert("Logout", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your session has expired. Please login again")
                }
    }

    var loginContent: some View {
        VStack {
                    ZStack {
                        Asset.Colors.e7E3EELightPurpuleBg.swiftUIColor
                            .ignoresSafeArea(edges: .top)
                        
                        HStack {
                            ZStack {
                                Asset.logo.swiftUIImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .clipShape(Circle())
                            .frame(width: 95, height: 95)
                            
                            Group {
                                VStack(alignment: .leading) {
                                    Text("AVIV")
                                        .font(FontFamily.Lato.regular.swiftUIFont(size: 52, relativeTo: .largeTitle))
                                    Text("ScoutRoute")
                                        .font(FontFamily.Lato.medium.swiftUIFont(size: 24, relativeTo: .title))
                                }
                            }
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.5) // "ScoutRoute" has no space to wrap on; shrink rather than truncate if it's ever too wide
                            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("AVIV ScoutRoute logo")
                        .padding([.bottom], 50)
                    }
                    .frame(minHeight: 250)
                                    
                    FloatingLabelTextField(title: "Username", text: $viewModel.username,
                                           accessibilityID: A11yID.Login.usernameField)
                        .padding(10)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.never)
                    
                    FloatingLabelTextField(title: "Password", text: $viewModel.password, isSecure:  true,
                                           accessibilityID: A11yID.Login.passwordField)
                        .padding(10)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.never)
                    
                    if debugMode {
                        Menu {
                            ForEach(APIEnvironment.allCases, id: \.self) { environment in
                                Button(action: {
                                    selectedEnvironment = environment
                                    APIConfiguration.shared.environment = environment
                                }) {
                                    Text(environment.displayString())
                                }
                            }
                        } label: {
                            HStack {
                                Text("Environment: \(selectedEnvironment.displayString())")
                                    .foregroundColor(.black)
                                Image(systemName: "chevron.down")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .accessibilityIdentifier(A11yID.Login.environmentPicker)
                        .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        APIConfiguration.shared.environment = selectedEnvironment
                        if forceUpdateManager?.validateForceUpdate() == .noUpdate {
                            viewModel.performLogin(for: selectedEnvironment)
                        }
                    }) {
                        Text("Login")
                            .font(FontFamily.Lato.bold.swiftUIFont(size: 20, relativeTo: .headline))
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Asset.Colors.huskyPurple.swiftUIColor)
                            .cornerRadius(25)
                    }
                    .accessibilityIdentifier(A11yID.Login.loginButton)
                    .padding(.top, 20)
                    .padding(.horizontal, 40)
                    
            forgotPassword
            iAmNewUser
            contactUs
            accessMapRoute
                    
                    if SessionManager.shared.canUseBiometricLogin(for: selectedEnvironment) {
                        Button(action: {
                            APIConfiguration.shared.environment = selectedEnvironment
                            BiometricAuthManager.authenticate(reason: "Login using Face ID") { result in
                                switch result {
                                case .success:
                                    if let username = KeychainManager.load(.username, for: selectedEnvironment),
                                       let password = KeychainManager.load(.password, for: selectedEnvironment) {

                                        viewModel.username = username
                                        viewModel.password = password
                                        
                                        viewModel.performLogin(for: selectedEnvironment)
                                    } else {
                                        print("Missing credentials in Keychain")
                                        viewModel.hasLoginFailed = true
                                        viewModel.loginFailedMessage = "Invalid Credentials"
                                    }

                                case .failure(let message), .unavailable(let message):
                                    print("Biometric login failed: \(message)")
                                    viewModel.hasLoginFailed = true
                                    viewModel.loginFailedMessage = message
                                }
                            }
                        }) {
                            Label(BiometricAuthManager.biometricLabelText(), systemImage: BiometricAuthManager.biometricIcon())
                                .font(FontFamily.Lato.bold.swiftUIFont(size: 18, relativeTo: .headline))
                                .foregroundColor(.blue)
                                .frame(minHeight: 44.0)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        .accessibilityIdentifier(A11yID.Login.biometricButton)
                        .padding(.top, 10)
                    }

                    if viewModel.hasLoginFailed {
                        Text(viewModel.loginFailedMessage ??  "Invalid Credentials")
                            .accessibilityIdentifier(A11yID.Login.errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 10)
                            .font(FontFamily.Lato.medium.swiftUIFont(size: 18, relativeTo: .headline))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                    if debugMode {
                        Button {
                            showDisableDebugModeAlert = true
                        } label: {
                            Text("Exit debug mode")
                                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                                .foregroundColor(Asset.Colors.d74BA827Pink.swiftUIColor)
                                .frame(minHeight: 44)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        .accessibilityIdentifier(A11yID.Login.exitDebugModeButton)
                        .padding(.bottom, 5)
                    }
                    HStack {
                        appVersionText
                            .accessibilityIdentifier(A11yID.Login.appVersionLabel)
                            .accessibilityRespondsToUserInteraction()
                            .onTapGesture(count: 7, perform: {
                                if !debugMode {
                                    showEnableDebugModeAlert = true
                                }
                            })

                        #if DEBUG
                        if UITestRuntime.isActive {
                            // XCUITest cannot reliably drive the native 7-tap gesture
                            // above: its synthesized taps are independent touch-down/
                            // touch-up pairs injected through XCTest's own event
                            // pipeline, which does not feed UIKit's multi-tap gesture
                            // recognizer the way a real finger does, regardless of how
                            // tightly they're spaced from the test side (confirmed:
                            // identical taps worked instantly by hand, never registered
                            // once under automation, padding the count made no
                            // difference either). Rather than change the real gesture to
                            // accommodate testing, this is an ADDITIONAL element that
                            // reaches the exact same state via one ordinary tap - which
                            // XCUITest handles perfectly reliably, as does every other
                            // interaction in this suite. It only exists when launched
                            // under a UI test (never in Release, and never during
                            // ordinary manual DEBUG-build use, since UITestRuntime
                            // .isActive is false in both), so it has zero effect on any
                            // real user or developer. The real 7-tap gesture above is
                            // completely unmodified.
                            //
                            // What this means for coverage: automated tests can fully
                            // exercise everything the debug-mode feature DOES once
                            // triggered (the alert, environment picker, disable flow),
                            // using this as a deterministic entry point - but they
                            // cannot verify that exactly 7 real taps, and not some other
                            // count, is what triggers it in production. That one detail
                            // needs a manual check.
                            Color.clear
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                                .accessibilityIdentifier(A11yID.Login.debugModeUITestUnlock)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityRespondsToUserInteraction()
                                .onTapGesture {
                                    if !debugMode {
                                        showEnableDebugModeAlert = true
                                    }
                                }
                        }
                        #endif
                    }
                    .frame(maxWidth: .infinity)
                    
                }
    }

    var appVersionText: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
        return Text("Version \(version)")
            .font(FontFamily.Lato.medium.swiftUIFont(size: 16, relativeTo: .headline))
            .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
            .padding(.horizontal, 10)
            .frame(minWidth: 44, minHeight: 44) // Explicitly meet accessibility standards
            .contentShape(Rectangle()) // Makes the whole 44x44 area tappable
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .accessibilityLabel("App version \(version)")
    }
    
    var forgotPassword: some View {
        Button(action: {
            openURL(url: "https://portal.tdei.us/ForgotPassword")
        }) {
            Text("Forgot password?")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .frame(minHeight: 44)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .accessibilityLabel("Forgot password?")
        }
        .accessibilityIdentifier(A11yID.Login.forgotPasswordButton)
    }
    
    var iAmNewUser: some View {
        Button(action: {
            openURL(url: "http://tinyurl.com/OTP2026Walk")
        }) {
            Text("I'm a new user")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .frame(minHeight: 44)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .accessibilityLabel("I'm a new user. Tap to learn more.")
        }
        .accessibilityIdentifier(A11yID.Login.newUserButton)
    }
    
    var contactUs: some View {
        Button(action:{
            openURL(url: "mailto:helpdesk@tdei.us")
        }) {
            Text("Questions? Contact Us")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .frame(minHeight: 44)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .accessibilityLabel("Questions? Contact Us. Tap to open email client")
        }
        .accessibilityIdentifier(A11yID.Login.contactUsButton)
    }
    
    var accessMapRoute: some View {
        Button(action:{
            openURL(url: "https://www.accessmap.app/dir?wp=-122.3346457_47.6059712%27-122.3310313_47.6062336&region=wa.seattle&lon=-122.3331631&lat=47.6070952&z=15.6&sa=1&mu=0.12&md=0.15&ab=1&aps=0")
        }) {
            Text("Looking for AccessMap Route?")
                .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .frame(minHeight: 44)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.bottom, 5)
                .accessibilityLabel("Looking for AccessMap Route? Tap to open AccessMap website")
            
        }
        .accessibilityIdentifier(A11yID.Login.accessMapButton)
    }
    
    private func openURL(url: String) {
        if let url = URL(string: url),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    PosmLoginView(forceUpdateManager: nil)
}
