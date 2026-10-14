import AVFoundation
import ComposableArchitecture
import SwiftUI
import UIKit

struct AstrologyView: View {
    @Bindable var store: StoreOf<AstrologyFeature>
    // binadble để gửi dc giá trị $store để nó có thể gọi trực tiếp dismis để tắt bật cái th này
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let compact = size.height > 0 && size.height < 720

            ZStack {
                AppTheme.Colors.Astrology.background
                    .ignoresSafeArea()

                if store.showVideoLayer {
                    AstrologyBackgroundVideoView(
                        shouldPlay: store.shouldPlayVideo,
                        onReadyChange: { isReady in
                            store.send(.videoReadyChanged(isReady))
                        },
                        onError: {
                            store.send(.videoPlaybackFailed)
                        }
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }

                if store.shouldShowFallbackImage {
                    Image(appAsset: .astrologyGalaxyBackground)
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(1, size.width), height: max(1, size.height))
                        .clipped()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                AppTheme.Colors.Astrology.videoTint
                    .opacity(0.10)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                if let geometry = store.geometry {
                    ConstellationCanvasView(geometry: geometry)
                        .ignoresSafeArea()
                }

                AppTheme.Gradients.Astrology.screenFade
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    headerBlock
                        .padding(.top, 8)
                        .padding(.horizontal, 18)

                    if store.geometryErrorMessage != nil {
                        geometryErrorBanner
                            .padding(.top, 36)
                            .padding(.horizontal, 28)
                    }

                    Spacer(minLength: 16)

                    bottomContent(compact: compact, totalWidth: size.width)
                        .padding(.horizontal, compact ? 18 : 24)
                        .padding(.bottom, 14)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            store.send(.reduceMotionChanged(reduceMotion))
            store.send(.scenePhaseChanged(isActive: scenePhase == .active))
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(isActive: newPhase == .active))
        }
        .onChange(of: reduceMotion) { _, newValue in
            store.send(.reduceMotionChanged(newValue))
        }
        .sheet(
            item: $store.scope(state: \.insight, action: \.insight)
        ) { insightStore in
            AstrologyInsightSheetView(store: insightStore)
                .presentationDetents([.fraction(0.88), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .sheet(
            item: Binding(
                get: { store.sharePayload },
                set: { newValue in
                    if newValue == nil {
                        store.send(.shareSheetDismissed)
                    }
                }
            )
        ) { payload in
            AstrologyActivityShareSheet(payload: payload)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header & Banners

    private var headerBlock: some View {
        VStack(spacing: 0) {
            Text("Numelyra")
                .font(.system(size: 31, weight: .regular, design: .serif))
                .tracking(0.6)
                .foregroundStyle(Color.white)
                .shadow(
                    color: AppTheme.Colors.Astrology.titleGlow.opacity(0.40),
                    radius: 12
                )

            HStack(spacing: 7) {
                Rectangle()
                    .fill(AppTheme.Colors.Astrology.accent)
                    .frame(width: 35, height: 0.5)

                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.Astrology.accent)

                Rectangle()
                    .fill(AppTheme.Colors.Astrology.accent)
                    .frame(width: 35, height: 0.5)
            }
            .padding(.top, 3)

            Text(store.dateHeaderText)
                .font(.system(size: 15, weight: .regular))
                .tracking(0.3)
                .foregroundStyle(AppTheme.Colors.Astrology.headerText)
                .shadow(color: Color.black.opacity(0.65), radius: 6)
                .padding(.top, 10)
        }
        .allowsHitTesting(false)
    }

    private var geometryErrorBanner: some View {
        HStack(spacing: 7) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.Astrology.accent)

            Text("Biểu tượng hôm nay đang tạm ẩn.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.Astrology.geometryErrorText)
        }
    }

    // MARK: - Bottom Content

    private func bottomContent(compact: Bool, totalWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(store.symbolLabelText)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.75)
                .foregroundStyle(AppTheme.Colors.Astrology.symbolLabel)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.90), radius: 6)
                .accessibilityAddTraits(.isHeader)

            if store.isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(AppTheme.Colors.Astrology.progress)

                    Text("Đang đọc bầu trời của bạn...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.Astrology.loadingText)
                }
                .frame(minHeight: 108)
            } else if let errorMessage = store.errorMessage {
                VStack(spacing: 10) {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .lineSpacing(3)
                        .foregroundStyle(AppTheme.Colors.Astrology.errorText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Button {
                        store.send(.retryTapped)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.Astrology.buttonText)

                            Text("Thử lại")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.Astrology.buttonTextStrong)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.Astrology.retryBackground.opacity(0.35))
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.Colors.Astrology.actionBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, minHeight: 104)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.Colors.Astrology.errorCardBackground.opacity(0.78))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            AppTheme.Colors.Astrology.accent.opacity(0.45),
                            lineWidth: 1
                        )
                )
                .padding(.top, 10)
            } else if let fortune = store.fortune {
                Text(store.fortuneTitleText)
                    .font(.system(size: compact ? 17 : 20, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.85), radius: 8)
                    .padding(.top, compact ? 6 : 9)

                Text(fortune.verse)
                    .font(.system(size: compact ? 17 : 20, weight: .regular, design: .serif).italic())
                    .lineSpacing(compact ? 4 : 6)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(compact ? 3 : 4)
                    .minimumScaleFactor(0.84)
                    .shadow(color: Color.black.opacity(0.90), radius: 8)
                    .padding(.top, compact ? 4 : 7)

                let horizontalPadding: CGFloat = (compact ? 18 : 24) * 2
                let availableRowWidth = max(240, totalWidth - horizontalPadding)
                let shareWidth = (availableRowWidth - 10) * 0.45
                let insightWidth = (availableRowWidth - 10) * 0.55

                HStack(spacing: 10) {
                    Button {
                        store.send(.shareTapped)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.Astrology.buttonText)

                            Text("Chia sẻ quẻ")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.Astrology.buttonText)
                        }
                        .frame(width: shareWidth, height: 48)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.Astrology.actionBackground.opacity(0.72))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    AppTheme.Colors.Astrology.actionBorder.opacity(0.85),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Chia sẻ quẻ")

                    Button {
                        store.send(.openInsightTapped)
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.Astrology.buttonText)

                            Text("Xem giải mã")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(AppTheme.Colors.Astrology.buttonTextStrong)
                        }
                        .frame(width: insightWidth, height: 48)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.Astrology.actionBackground.opacity(0.78))
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.Colors.Astrology.actionBorder, lineWidth: 1)
                        )
                        .shadow(
                            color: AppTheme.Colors.Astrology.actionGlow.opacity(0.38),
                            radius: 12
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 15)
            }
        }
    }
}

// MARK: - Looping Background Video View (AVQueuePlayer + AVPlayerLooper)

private struct AstrologyBackgroundVideoView: UIViewRepresentable {
    let shouldPlay: Bool
    let onReadyChange: (Bool) -> Void
    let onError: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReadyChange: onReadyChange, onError: onError)
    }

    func makeUIView(context: Context) -> VideoContainerView {
        let view = VideoContainerView()
        context.coordinator.attach(to: view, shouldPlay: shouldPlay)
        return view
    }

    func updateUIView(_ uiView: VideoContainerView, context: Context) {
        context.coordinator.onReadyChange = onReadyChange
        context.coordinator.onError = onError
        context.coordinator.updatePlayback(shouldPlay: shouldPlay)
    }

    static func dismantleUIView(_ uiView: VideoContainerView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class VideoContainerView: UIView {
        override static var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            // Safe cast because layerClass is AVPlayerLayer.self
            layer as! AVPlayerLayer
        }
    }

    final class Coordinator {
        var onReadyChange: (Bool) -> Void
        var onError: () -> Void

        private var queuePlayer: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var readyObservation: NSKeyValueObservation?
        private var statusObservation: NSKeyValueObservation?

        init(onReadyChange: @escaping (Bool) -> Void, onError: @escaping () -> Void) {
            self.onReadyChange = onReadyChange
            self.onError = onError
        }

        func attach(to view: VideoContainerView, shouldPlay: Bool) {
            guard let url = AppAsset.astrologyAuroraVideoURL else {
                DispatchQueue.main.async { [weak self] in
                    self?.onError()
                }
                return
            }

            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])

            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer(playerItem: item)
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
            player.actionAtItemEnd = .none

            let playerLooper = AVPlayerLooper(player: player, templateItem: item)
            self.queuePlayer = player
            self.looper = playerLooper

            view.playerLayer.player = player
            view.playerLayer.videoGravity = .resizeAspectFill

            readyObservation = view.playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
                let ready = layer.isReadyForDisplay
                DispatchQueue.main.async {
                    self?.onReadyChange(ready)
                }
            }

            statusObservation = player.observe(\.status, options: [.new]) { [weak self] observedPlayer, _ in
                if observedPlayer.status == .failed {
                    DispatchQueue.main.async {
                        self?.onError()
                    }
                }
            }

            updatePlayback(shouldPlay: shouldPlay)
        }

        func updatePlayback(shouldPlay: Bool) {
            guard let queuePlayer else { return }
            if shouldPlay {
                if queuePlayer.timeControlStatus != .playing {
                    queuePlayer.play()
                }
            } else {
                queuePlayer.pause()
            }
        }

        func teardown() {
            readyObservation?.invalidate()
            readyObservation = nil
            statusObservation?.invalidate()
            statusObservation = nil
            queuePlayer?.pause()
            looper?.disableLooping()
            looper = nil
            queuePlayer = nil
        }
    }
}

// MARK: - Native Share Sheet

private struct AstrologyActivityShareSheet: UIViewControllerRepresentable {
    let payload: AstrologyFeature.SharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [payload.message],
            applicationActivities: nil
        )
        controller.setValue(payload.title, forKey: "subject")
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AstrologyView(
        store: Store(initialState: AstrologyFeature.State()) {
            AstrologyFeature()
        } withDependencies: {
            $0.astrologyClient = .previewValue
            $0.caDaoClient = .previewValue
            $0.userProfileClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}
