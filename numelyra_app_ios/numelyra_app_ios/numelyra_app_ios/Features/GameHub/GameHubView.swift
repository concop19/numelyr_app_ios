import ComposableArchitecture
import SwiftUI

struct GameHubView: View {
    @Bindable var store: StoreOf<GameHubFeature>

    private let gameItems: [(id: GameId, title: String, subtitle: String, emoji: String, color: Color)] = [
        (.arrowEscape, "Arrow Escape", "40 màn giải đố mũi tên", "🏹", Color(hex: 0x6D4AFF)),
        (.mindRules, "Mind Rules", "48 quy luật số", "🧠", Color(hex: 0xF05A9D)),
        (.oAnQuan, "Ô Ăn Quan", "Đấu trí cùng AI", "🪨", Color(hex: 0xD98935)),
        (.dotsBoxes, "Nối Ô", "Đối kháng PvE/PvP", "✦", Color(hex: 0x24A89A)),
        (.sudoku, "Sudoku", "Bốn mức độ khó", "🔢", Color(hex: 0x3E7DDB)),
        (.game2048, "2048", "Chạm mốc cao mới", "🔷", Color(hex: 0xC752A4)),
        (.zip, "Zip", "24 puzzle và Daily", "〰️", Color(hex: 0x7E58D1)),
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            AppScreenBackground()
                .allowsHitTesting(false)

            if let selectedGame = store.selectedGame {
                gameRunnerView(gameId: selectedGame)
            } else {
                hubScrollView
            }
        }
        .preferredColorScheme(.dark)
        .task { store.send(.onAppear) }
    }

    // MARK: - Hub Main Screen
    private var hubScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Nút quay lại
                Button {
                    store.send(.closeTapped)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Trò chuyện")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.Colors.primaryBright)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .padding(.bottom, 16)

                // Hero
                VStack(alignment: .leading, spacing: 4) {
                    Text("NUMELYRA PLAY")
                        .font(.system(size: 12, weight: .heavy))
                        .kerning(1.5)
                        .foregroundStyle(AppTheme.Colors.primaryBright)

                    Text("Game Hub")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text("Chơi một chút mỗi ngày, nuôi dưỡng trí óc và giữ chuỗi của bạn.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.top, 2)
                }
                .padding(.bottom, 22)

                // Daily Challenge Card
                dailyChallengeCard
                    .padding(.bottom, 28)

                // Tất cả trò chơi
                Text("Tất cả trò chơi")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.bottom, 14)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(gameItems, id: \.id) { item in
                        gameCard(item: item)
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Daily Challenge Card
    private var dailyChallengeCard: some View {
        Button {
            store.send(.dailyChallengeTapped)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("✦ DAILY CHALLENGE")
                        .font(.system(size: 11, weight: .heavy))
                        .kerning(1.2)
                        .foregroundStyle(AppTheme.Colors.primaryBright)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(store.streak) ngày")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: 0xFF9800))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: 0xFF9800).opacity(0.15))
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.dailyChallenge.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text(store.dailyChallenge.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                HStack {
                    Text(store.isDailyCompleted ? "✓ Đã hoàn thành hôm nay" : "Chơi thử thách hôm nay  ›")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(store.isDailyCompleted ? Color(hex: 0x4CAF50) : AppTheme.Colors.primaryBright)

                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x2A1B4E), Color(hex: 0x1B1038)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.Colors.primaryBright.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: AppTheme.Colors.primaryBright.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game Card
    private func gameCard(item: (id: GameId, title: String, subtitle: String, emoji: String, color: Color)) -> some View {
        Button {
            store.send(.gameSelected(item.id))
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(item.color.opacity(0.25))
                            .frame(width: 44, height: 44)
                        Text(item.emoji)
                            .font(.system(size: 22))
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)

                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(Color(hex: 0x1A1435))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game Runner / Shell
    private func gameRunnerView(gameId: GameId) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    store.send(.closeGameTapped)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Game Hub")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.Colors.primaryBright)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(gameId.titleVi)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
                Color.clear.frame(width: 80, height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Spacer()

            VStack(spacing: 18) {
                Text(gameEmoji(for: gameId))
                    .font(.system(size: 72))

                Text(gameId.titleVi)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                if store.isDailyMode {
                    VStack(spacing: 8) {
                        Text("✦ THỬ THÁCH HÔM NAY")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(AppTheme.Colors.primaryBright)

                        Text(store.dailyChallenge.subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                        if !store.isDailyCompleted {
                            Button {
                                store.send(.completeDailyTapped)
                            } label: {
                                Text("Hoàn thành thử thách hôm nay")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x0B0B14))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.Gradients.goldAction)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 12)
                        } else {
                            Text("✓ Đã hoàn thành thử thách hôm nay!")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x4CAF50))
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: 0x1E153A))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("Trò chơi đang sẵn sàng. Hãy tập trung và vượt qua thử thách!")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func gameEmoji(for id: GameId) -> String {
        switch id {
        case .arrowEscape: return "🏹"
        case .mindRules: return "🧠"
        case .oAnQuan: return "🪨"
        case .dotsBoxes: return "✦"
        case .sudoku: return "🔢"
        case .game2048: return "🔷"
        case .zip: return "〰️"
        }
    }
}

#Preview {
    GameHubView(
        store: Store(initialState: GameHubFeature.State()) {
            GameHubFeature()
        } withDependencies: {
            $0.gameHubClient = .previewValue
        }
    )
}
