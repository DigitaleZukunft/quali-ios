//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationStartScreenViewModelType = StateStoreViewModelV2<AuthenticationStartScreenViewState, AuthenticationStartScreenViewAction>

class AuthenticationStartScreenViewModel: AuthenticationStartScreenViewModelType, AuthenticationStartScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let provisioningParameters: AccountProvisioningParameters?
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let canReportProblem: Bool
    
    private var actionsSubject: PassthroughSubject<AuthenticationStartScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AuthenticationStartScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(authenticationService: AuthenticationServiceProtocol,
         provisioningParameters: AccountProvisioningParameters?,
         isBugReportServiceEnabled: Bool,
         appSettings: AppSettings,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.authenticationService = authenticationService
        self.provisioningParameters = provisioningParameters
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController
        canReportProblem = isBugReportServiceEnabled
        
        let isQRCodeScanningSupported = !ProcessInfo.processInfo.isiOSAppOnMac
        
        let initialViewState = if !appSettings.allowOtherAccountProviders {
            // We don't show the create account button when custom providers are disallowed.
            // The assumption here being that if you're running a custom app, your users will already be created.
            AuthenticationStartScreenViewState(serverName: appSettings.accountProviders.count == 1 ? appSettings.accountProviders[0] : nil,
                                               showCreateAccountButton: false,
                                               // Disable QR login to avoid non-SSO flows in the Quali build
                                               showQRCodeLoginButton: false)
        } else if let provisioningParameters {
            // We only show the "Sign in to …" button when using a provisioning link.
            AuthenticationStartScreenViewState(serverName: provisioningParameters.accountProvider,
                                               showCreateAccountButton: false,
                                               showQRCodeLoginButton: false)
        } else {
            // The default configuration.
            AuthenticationStartScreenViewState(serverName: nil,
                                               showCreateAccountButton: appSettings.showCreateAccountButton,
                                               showQRCodeLoginButton: isQRCodeScanningSupported)
        }
        
        super.init(initialViewState: initialViewState)
    }

    override func process(viewAction: AuthenticationStartScreenViewAction) {
        switch viewAction {
        case .updateWindow(let window):
            guard state.window != window else { return }
            state.window = window
        case .loginWithQR:
            actionsSubject.send(.loginWithQR)
        case .login:
            Task { await loginWithQualiWalletSSO() }
        case .loginWithEthereumWallet:
            Task { await loginWithSpecificWallet(idp: "oidc-siwe") }
        case .loginWithSuperheroWallet:
            Task { await loginWithSpecificWallet(idp: "oidc-aeternity") }
        case .register:
            actionsSubject.send(.register)
        case .reportProblem:
            if canReportProblem {
                actionsSubject.send(.reportProblem)
            }
        }
    }
    
    // MARK: - Private
    
    private func login() async {
        if let serverName = state.serverName {
            await configureAccountProvider(serverName, loginHint: provisioningParameters?.loginHint)
        } else {
            actionsSubject.send(.login) // No need to configure anything here, continue the flow.
        }
    }

    private func loginWithQualiWalletSSO() async {
        // Proceed via OIDC SSO on the Quali homeserver (wallet IdPs configured)
        await configureAccountProvider("matrix.quali.chat", loginHint: nil)
    }

    private func loginWithSpecificWallet(idp: String) async {
        startLoading()
        defer { stopLoading() }
        // Force the Quali homeserver
        guard case .success = await authenticationService.configure(for: "matrix.quali.chat", flow: .login) else {
            displayError()
            return
        }
        // If the MAS-issued OIDC URL is available, prefer web auth session flow
        if let window = state.window {
            switch await authenticationService.urlForOIDCLogin(loginHint: nil) {
            case .success(let oidcData):
                actionsSubject.send(.loginDirectlyWithOIDC(data: oidcData, window: window))
                return
            case .failure:
                break
            }
        }
        // Fallback: open Synapse SSO redirect to a specific IdP which will eventually return an m.login.token
        guard let redirectURL = authenticationService.ssoRedirectURL(redirectScheme: InfoPlistReader.main.baseBundleIdentifier, idp: idp) else {
            displayError()
            return
        }
        await MainActor.run {
            UIApplication.shared.open(redirectURL)
        }
    }
    
    private func configureAccountProvider(_ accountProvider: String, loginHint: String? = nil) async {
        startLoading()
        defer { stopLoading() }
        
        guard case .success = await authenticationService.configure(for: accountProvider, flow: .login) else {
            // As the server was provisioned, we don't worry about the specifics and show a generic error to the user.
            displayError()
            return
        }
        
        // For quali.chat build, enforce SSO regardless of advertised login modes.
        
        guard let window = state.window else {
            displayError()
            return
        }
        
        switch await authenticationService.urlForOIDCLogin(loginHint: loginHint) {
        case .success(let oidcData):
            actionsSubject.send(.loginDirectlyWithOIDC(data: oidcData, window: window))
        case .failure:
            // Fallback to Synapse SSO redirect + m.login.token
            guard let redirectURL = authenticationService.ssoRedirectURL(redirectScheme: InfoPlistReader.main.baseBundleIdentifier, idp: nil) else {
                displayError()
                return
            }
            await MainActor.run {
                UIApplication.shared.open(redirectURL)
            }
        }
    }
    
    private let loadingIndicatorID = "\(AuthenticationStartScreenViewModel.self)-Loading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorID,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorID)
    }
    
    private func displayError() {
        state.bindings.alertInfo = AlertInfo(id: .genericError)
    }
}
