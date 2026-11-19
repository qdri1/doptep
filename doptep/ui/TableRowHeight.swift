//
//  TableRowHeight.swift
//  doptep
//

import SwiftUI

/// Same height for every cell of the column-based leaderboards.
///
/// The tables are built column by column (#, name, each stat), so rows only line up if every
/// cell has the same height. The name column contains a fixed 16pt colour badge, while text in
/// the other columns follows the system font size — with a smaller system font the text rows got
/// shorter than the badge rows and the columns drifted apart. The height scales with Dynamic Type
/// like the Montserrat fonts do, but never drops below the badge.
struct TableRowHeight: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var scaledHeight: CGFloat = 18

    func body(content: Content) -> some View {
        content.frame(height: max(scaledHeight, 17))
    }
}

extension View {
    func tableRowHeight() -> some View {
        modifier(TableRowHeight())
    }
}
