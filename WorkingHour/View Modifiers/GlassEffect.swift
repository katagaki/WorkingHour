//
//  GlassEffect.swift
//  WorkingHour
//
//  Created by シン・ジャスティン on 2026/04/10.
//

import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular, in: .rect(cornerRadius: 28.0))
        } else {
            self
                .padding(4.0)
                .background(Material.bar)
                .clipShape(.rect(cornerRadius: 28.0))
        }
    }
}
