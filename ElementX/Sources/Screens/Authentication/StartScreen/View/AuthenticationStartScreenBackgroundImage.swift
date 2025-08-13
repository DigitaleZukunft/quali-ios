//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The background gradient shown on the launch, splash and onboarding screens.
struct AuthenticationStartScreenBackgroundImage: View {
    var body: some View {
        LinearGradient(colors: [
            Color(red: 0.06, green: 0.07, blue: 0.09),
            Color(red: 0.06, green: 0.23, blue: 0.31),
            Color(red: 0.08, green: 0.35, blue: 0.52)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.08), Color.clear]), center: .center, startRadius: 0, endRadius: 380)
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
