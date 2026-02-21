//
//  Resizer.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 02/08/24.
//

import SwiftUI

/// Holds the column width at drag start. Using a class avoids SwiftUI
/// re-render resetting the value mid-gesture.
private class DragState {
    var initialWidth: CGFloat?
}

struct Resizer: View {
    var columnHeight: CGFloat = 24

    @Binding var columnWidth: CGFloat
    private let dragState = DragState()

    var body: some View {
        Color(nsColor: .separatorColor)
            .frame(width: 1, height: columnHeight)
            .overlay {
                Color.clear
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .cursor(.resizeLeftRight)
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if dragState.initialWidth == nil {
                                    dragState.initialWidth = columnWidth
                                }
                                let proposed = (dragState.initialWidth ?? columnWidth) + value.translation.width
                                columnWidth = max(proposed, 60)
                            }
                            .onEnded { _ in
                                dragState.initialWidth = nil
                            }
                    )
            }
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
