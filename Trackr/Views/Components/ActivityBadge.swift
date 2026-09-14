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
    /// Overrides `kind.tint`, e.g. to distinguish Active vs. Passive immersion.
    var tint: Color? = nil

    private var resolvedTint: Color { tint ?? kind.tint }

    var body: some View {
        Image(systemName: kind.systemImage)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(resolvedTint)
            .frame(width: size, height: size)
            .background(resolvedTint.opacity(0.15), in: .rect(cornerRadius: size * 0.3))
            .accessibilityLabel(kind.displayName)
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(ActivityKind.allCases) { ActivityBadge(kind: $0) }
    }
    .padding()
}
