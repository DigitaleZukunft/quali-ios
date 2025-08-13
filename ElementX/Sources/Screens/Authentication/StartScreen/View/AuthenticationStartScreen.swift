//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let context: AuthenticationStartScreenViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
                
                content
                    .frame(width: geometry.size.width)
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.hidden)
                
                buttons
                    .frame(width: geometry.size.width)
                    .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                    .padding(.top, 8)
                
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                versionText
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    .onTapGesture(count: 7) {
                        context.send(viewAction: .reportProblem)
                    }
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.appVersion)
            }
        }
        .navigationBarHidden(true)
		.background {
			ZStack {
				AuthenticationStartScreenBackgroundImage()
				Color.black.opacity(0.40).ignoresSafeArea()
			}
		}
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            Spacer()
            
			if verticalSizeClass == .regular {
                Spacer()
                
                AuthenticationStartLogo(isOnGradient: true)
				brandWordmark
            }
            
            Spacer()
            
			VStack(spacing: 12) {
				Text("Gate your community, not your vibe")
					.font(.compound.headingLGBold)
					.foregroundColor(.white)
					.multilineTextAlignment(.center)
				LinearGradient(
					colors: [
						Color(red: 124/255, green: 92/255, blue: 255/255),
						Color(red: 255/255, green: 92/255, blue: 243/255),
						Color(red: 0/255, green: 230/255, blue: 179/255)
					],
					startPoint: .leading,
					endPoint: .trailing
				)
				.mask(
					Text("Token‑gated chats. Zero noise. All signal.")
						.font(.compound.bodyMD)
						.fontWeight(.bold)
						.multilineTextAlignment(.center)
						.lineLimit(2)
						.minimumScaleFactor(0.85)
						.allowsTightening(true)
				)
				Text("We verify tokens instantly so only real holders enter. Enjoy spam‑free, troll‑proof convos that actually move your community forward.")
					.font(.compound.bodyMD)
					.foregroundColor(.white.opacity(0.85))
					.multilineTextAlignment(.center)
					.lineLimit(nil)
					.fixedSize(horizontal: false, vertical: true)
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 8) {
						ForEach(["Ethereum", "Solana", "BSC", "Polygon", "Base"], id: \.self) { chain in
							Text(chain)
								.font(.compound.bodySM)
								.fontWeight(.semibold)
								.foregroundColor(.white.opacity(0.75))
								.lineLimit(1)
								.minimumScaleFactor(0.9)
								.fixedSize(horizontal: true, vertical: false)
								.padding(.vertical, 6)
								.padding(.horizontal, 10)
								.background(Color.white.opacity(0.06), in: Capsule())
								.overlay(
									Capsule()
										.stroke(Color.white.opacity(0.12), lineWidth: 1)
								)
						}
					}
				}
			}
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }

	private var brandWordmark: some View {
		HStack(spacing: 0) {
			Text("quali")
				.foregroundColor(.white)
			Text(".chat")
				.foregroundColor(Color(red: 124/255, green: 92/255, blue: 255/255))
		}
		.font(.system(size: 22, weight: .bold, design: .rounded))
		.multilineTextAlignment(.center)
		.padding(.top, 8)
	}
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 16) {
            if context.viewState.showQRCodeLoginButton {
                Button { context.send(viewAction: .loginWithQR) } label: {
                    Label(L10n.screenOnboardingSignInWithQrCode, icon: \.qrCode)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signInWithQr)
            }
            
			// Preferred wallet-specific SSO entries
			Button { context.send(viewAction: .loginWithEthereumWallet) } label: {
				Text("Connect wallet")
			}
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signIn)
            
            if context.viewState.showCreateAccountButton {
                Button { context.send(viewAction: .register) } label: {
                    Text(L10n.screenCreateAccountTitle)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }
    
    var versionText: Text {
        // Let's not deal with snapshotting a changing version string.
        let shortVersionString = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        return Text(L10n.screenOnboardingAppVersion(shortVersionString))
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let provisionedViewModel = makeViewModel(provisionedServerName: "example.com")
    
    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AuthenticationStartScreen(context: provisionedViewModel.context)
            .previewDisplayName("Provisioned")
    }
    
    static func makeViewModel(provisionedServerName: String? = nil) -> AuthenticationStartScreenViewModel {
        AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock,
                                           provisioningParameters: provisionedServerName.map { .init(accountProvider: $0, loginHint: nil) },
                                           isBugReportServiceEnabled: true,
                                           appSettings: ServiceLocator.shared.settings,
                                           userIndicatorController: UserIndicatorControllerMock())
    }
}
