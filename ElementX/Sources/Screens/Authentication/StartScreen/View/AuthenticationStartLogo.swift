//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The app's logo styled to fit on various launch pages.
struct AuthenticationStartLogo: View {
    /// Set to `true` when using on top of a gradient background.
    let isOnGradient: Bool
    
    var body: some View {
        if let url = URL(string: ServiceLocator.shared.settings.logoURL.absoluteString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white.opacity(0.8))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    fallbackTitle
                @unknown default:
                    fallbackTitle
                }
            }
            .frame(width: 120, height: 120)
            .shadow(color: .black.opacity(isOnGradient ? 0.45 : 0.2), radius: 10, y: 6)
            .accessibilityHidden(true)
        } else {
            fallbackTitle
        }
    }

    private var fallbackTitle: some View {
        HStack(spacing: 0) {
            Text("quali")
            Text(".")
                .baselineOffset(-1)
            Text("chat")
        }
        .font(.system(size: 44, weight: .heavy, design: .rounded))
        .kerning(-0.5)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(isOnGradient ? 0.45 : 0.2), radius: 10, y: 6)
        .accessibilityHidden(true)
    }
}
