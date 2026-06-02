//
//  PlayerTeamBadge.swift
//  doptep
//

import SwiftUI

struct PlayerTeamBadge: View {
    let teamColor: TeamColor
    let number: Int?
    var size: CGFloat = 16

    private var cornerRadius: CGFloat { size * 0.25 }
    private var fontSize: CGFloat { size * 0.5 }
    private var horizontalPadding: CGFloat { size * 0.25 }

    var body: some View {
        if let number = number {
            Text("\(number)")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(teamColor == .white ? AppColor.onSurface : .white)
                .padding(.horizontal, horizontalPadding)
                .frame(minWidth: size, minHeight: size)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(teamColor.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(teamColor == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                        )
                )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(teamColor.color)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(teamColor == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
                )
        }
    }
}
