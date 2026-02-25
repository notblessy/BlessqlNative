import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager

    @State private var hoveredTabID: UUID? = nil
    @State private var scrollOffset: Int = 0

    private let tabHeight: CGFloat = 30
    private let maxVisibleTabs = 6

    private var canScrollPrev: Bool { scrollOffset > 0 }
    private var canScrollNext: Bool { scrollOffset + maxVisibleTabs < tabManager.tabs.count }

    private var visibleTabs: [WorkspaceTab] {
        let start = scrollOffset
        let end = min(start + maxVisibleTabs, tabManager.tabs.count)
        guard start < tabManager.tabs.count else { return [] }
        return Array(tabManager.tabs[start..<end])
    }

    var body: some View {
        HStack(spacing: 0) {
            navButtons

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.3))
                .frame(width: 1, height: 16)
                .padding(.trailing, 4)

            ForEach(visibleTabs) { tab in
                tabItem(tab)
                    .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 4)
        }
        .frame(height: tabHeight)
        .background(Color(hex: "E6E5E6"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.4)).frame(height: 1)
        }
        .onChange(of: tabManager.activeTabID) { newID in
            guard let newID,
                  let idx = tabManager.tabs.firstIndex(where: { $0.id == newID }) else { return }
            if idx < scrollOffset {
                scrollOffset = idx
            } else if idx >= scrollOffset + maxVisibleTabs {
                scrollOffset = idx - maxVisibleTabs + 1
            }
        }
    }

    // MARK: - Nav Buttons

    private var navButtons: some View {
        HStack(spacing: 0) {
            Button {
                if canScrollPrev { scrollOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(canScrollPrev ? Color(hex: "676667") : Color(hex: "AFAFAF"))
            }
            .buttonStyle(.plain)
            .frame(width: 22, height: tabHeight)
            .contentShape(Rectangle())
            .disabled(!canScrollPrev)

            Button {
                if canScrollNext { scrollOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(canScrollNext ? Color(hex: "676667") : Color(hex: "AFAFAF"))
            }
            .buttonStyle(.plain)
            .frame(width: 22, height: tabHeight)
            .contentShape(Rectangle())
            .disabled(!canScrollNext)
        }
    }

    // MARK: - Tab Item

    @ViewBuilder
    private func tabItem(_ tab: WorkspaceTab) -> some View {
        let isActive = tabManager.activeTabID == tab.id
        let isHovered = hoveredTabID == tab.id

        HStack(spacing: 0) {
            Spacer(minLength: 4)

            Text(tab.title)
                .font(.system(size: 11, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? .primary : Color(hex: "676667"))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Button {
                tabManager.closeTab(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(isActive ? .secondary : Color(hex: "676667"))
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isActive || isHovered ? 1.0 : 0.0)
            .padding(.trailing, 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: tabHeight)
        .background(isActive ? Color.white : Color.clear)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.4))
                .frame(width: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tabManager.switchToTab(tab.id)
        }
        .onHover { hovering in
            hoveredTabID = hovering ? tab.id : nil
        }
        .contextMenu {
            Button("Close") { tabManager.closeTab(tab.id) }
            Button("Close Others") {
                let otherIDs = tabManager.tabs
                    .filter { $0.id != tab.id }
                    .map(\.id)
                for id in otherIDs {
                    tabManager.closeTab(id)
                }
            }
        }
    }
}
