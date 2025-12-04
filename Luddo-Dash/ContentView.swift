//
//  ContentView.swift
//  Luddo-Dash
//
//  Main navigation with carousel tab bar
//

import SwiftUI

// MARK: - Navigation Item
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case games = "Games"
    case ai = "AI"
    case gpt = "GPT"
    case learn = "Learn"
    case system = "System"
    case utilities = "Utils"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .games: return "gamecontroller.fill"
        case .ai: return "brain.fill"
        case .gpt: return "wand.and.stars"
        case .learn: return "brain.head.profile"
        case .system: return "cpu.fill"
        case .utilities: return "globe"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .dashboardBlue
        case .games: return .gamesTeal
        case .ai: return .aiIndigo
        case .gpt: return .liveAIOrange
        case .learn: return .learnPurple
        case .system: return .systemPink
        case .utilities: return .utilsGreen
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @State private var selectedItem: NavigationItem = .dashboard
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedItem {
                case .dashboard:
                    DashboardView()
                case .games:
                    GamesView()
                case .ai:
                    AIAnalyticsView()
                case .gpt:
                    LiveAIView()
                case .learn:
                    LearnView()
                case .system:
                    SystemMonitorView()
                case .utilities:
                    UtilitiesView()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedItem)

            // Carousel Tab Bar
            CarouselTabBar(selectedItem: $selectedItem, dragOffset: $dragOffset)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Carousel Tab Bar
struct CarouselTabBar: View {
    @Binding var selectedItem: NavigationItem
    @Binding var dragOffset: CGFloat

    private let items = NavigationItem.allCases
    private let itemWidth: CGFloat = 56
    private let spacing: CGFloat = 8

    // Liquid glass blue color
    private let liquidBlue = Color(red: 0/255, green: 102/255, blue: 204/255)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // Liquid glass blue background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    liquidBlue.opacity(0.25),
                                    liquidBlue.opacity(0.15),
                                    Color(red: 0.1, green: 0.4, blue: 0.8).opacity(0.2),
                                    liquidBlue.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            // Glass material layer
                            RoundedRectangle(cornerRadius: 30)
                                .fill(.ultraThinMaterial)
                                .opacity(0.7)
                        )
                        .overlay(
                            // Inner highlight for liquid effect
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1),
                                            liquidBlue.opacity(0.3),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .padding(1)
                        )
                        .overlay(
                            // Outer border gradient
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            liquidBlue.opacity(0.6),
                                            liquidBlue.opacity(0.3),
                                            Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.5),
                                            liquidBlue.opacity(0.6)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: liquidBlue.opacity(0.35), radius: 20, x: 0, y: -8)
                        .shadow(color: liquidBlue.opacity(0.2), radius: 10, x: 0, y: -4)
                        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)

                    // Animated glow effect for selected item
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [selectedItem.color.opacity(0.5), selectedItem.color.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 15)
                        .offset(y: -15)

                    // Items - Scrollable with auto-scroll to selected
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: spacing) {
                                ForEach(items) { item in
                                    TabBarItem(
                                        item: item,
                                        isSelected: item == selectedItem,
                                        onTap: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                selectedItem = item
                                            }
                                            FeedbackManager.shared.tabSelectionFeedback()
                                        }
                                    )
                                    .frame(width: itemWidth)
                                    .id(item)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .onChange(of: selectedItem) { _, newValue in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
                .frame(height: 90)
                .padding(.horizontal, 16)
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
            }
        }
        .frame(height: 100)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let item: NavigationItem
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Selected background circle
                if isSelected {
                    Circle()
                        .fill(item.color)
                        .frame(width: 42, height: 42)
                        .shadow(color: item.color.opacity(0.4), radius: 6, x: 0, y: 3)
                }

                Image(systemName: item.icon)
                    .font(.system(size: isSelected ? 18 : 17))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .frame(width: 42, height: 42)

            Text(item.rawValue)
                .font(.system(size: 9))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? item.color : .secondary)
                .lineLimit(1)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
