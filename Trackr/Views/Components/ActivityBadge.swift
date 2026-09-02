//
//  ActivityBadge.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI

/// A rounded, tinted icon chip representing an activity kind.
struct ActivityBadge: View {
    let kind: ActivityKind
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: kind.systemImage)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(kind.tint)
            .frame(width: size, height: size)
            .background(kind.tint.opacity(0.15), in: .rect(cornerRadius: size * 0.3))
            .accessibilityLabel(kind.displayName)
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(ActivityKind.allCases) { ActivityBadge(kind: $0) }
    }
    .padding()
}
