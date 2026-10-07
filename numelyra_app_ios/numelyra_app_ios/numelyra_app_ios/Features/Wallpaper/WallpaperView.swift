import ComposableArchitecture
import SwiftUI

struct WallpaperView: View {
    @Bindable var store: StoreOf<WallpaperFeature>
    @FocusState private var promptFocused: Bool

    var body: some View {
        ZStack {
            WallpaperPalette.background.ignoresSafeArea()

            if store.step == .input {
                inputBackground
            }

            VStack(spacing: 0) {
                header

                switch store.step {
                case .input:
                    inputContent
                case .generating:
                    generatingContent
                case .result:
                    resultContent
                }
            }

            if let message = store.toastMessage {
                toast(message)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: store.step)
        .animation(.easeInOut(duration: 0.2), value: store.toastMessage)
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            WallpaperDetailView(store: detailStore)
        }
        .sheet(item: $store.scope(state: \.menu, action: \.menu)) { menuStore in
            WallpaperMenuView(store: menuStore)
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .sheet(item: $store.scope(state: \.profilePicker, action: \.profilePicker)) { profileStore in
            WallpaperProfileView(store: profileStore)
                .presentationDetents([.height(470)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .fullScreenCover(item: $store.scope(state: \.numerologyCards, action: \.numerologyCards)) { cardsStore in
            NumerologyCardsView(store: cardsStore)
        }
    }

    private var inputBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Image(appAsset: .wallpaperLandscapeBackground)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                FloatingWallpaperCloudView()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var header: some View {
        HStack {
            Button {
                promptFocused = false
                store.send(.backTapped)
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(WallpaperPalette.gold)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quay lại")

            Spacer()

            Button {
                promptFocused = false
                store.send(.profileTapped)
            } label: {
                Image(systemName: "person.crop.circle.badge.magnifyingglass")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(WallpaperPalette.gold)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Chọn hồ sơ")

            Button {
                promptFocused = false
                store.send(.menuTapped)
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Mở menu")
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
    }

    private var inputContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Create your\nlucky wallpaper")
                            .font(.system(size: promptFocused ? 28 : 34, weight: .bold, design: .rounded))
                            .tracking(-0.4)
                            .foregroundStyle(.white)

                        Text("Describe your vibe, mood or what\nyou need right now.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(WallpaperPalette.mutedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    MoonDecorationView()
                        .frame(width: promptFocused ? 66 : 88, height: promptFocused ? 66 : 88)
                }

                promptField
                    .padding(.top, promptFocused ? 14 : 28)

                Spacer(minLength: promptFocused ? 260 : 430)
            }
            .padding(.horizontal, 24)
            .padding(.top, promptFocused ? 4 : 16)
            .padding(.bottom, 30)
            .animation(.easeInOut(duration: 0.24), value: promptFocused)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var promptField: some View {
        HStack(spacing: 9) {
            Button {
                store.send(.profileTapped)
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color(hexValue: 0xC8B9E4))
                    .frame(width: 28, height: 40)
            }
            .accessibilityLabel("Chọn hồ sơ")

            TextField(
                "Falling asleep...",
                text: Binding(
                    get: { store.prompt },
                    set: { store.send(.promptChanged($0)) }
                )
            )
            .focused($promptFocused)
            .submitLabel(.go)
            .onSubmit {
                promptFocused = false
                store.send(.generateTapped)
            }
            .foregroundStyle(.white)
            .tint(WallpaperPalette.gold)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()

            Button {
                promptFocused = false
                store.send(.generateTapped)
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WallpaperPalette.deepPurple)
                    .frame(width: 44, height: 44)
                    .background(WallpaperPalette.goldGradient)
                    .clipShape(Circle())
                    .shadow(color: Color(hexValue: 0xE4A039).opacity(0.5), radius: 10, y: 4)
            }
            .accessibilityLabel("Tạo hình nền")
        }
        .padding(.leading, 11)
        .padding(.trailing, 5)
        .frame(height: 56)
        .background(Color(hexValue: 0x38245A).opacity(0.82))
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color(hexValue: 0x8E69C4).opacity(0.48), lineWidth: 1.5) }
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    private var generatingContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Creating your\nlucky wallpaper...")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Turning your words into a scene ✨")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(WallpaperPalette.mutedText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            FloatingCardStackView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                ProgressView().tint(WallpaperPalette.gold)
                Text("Painting your scene...")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color(hexValue: 0x301E4E).opacity(0.9))
            .clipShape(Capsule())
            .overlay { Capsule().stroke(Color(hexValue: 0x8E69C4).opacity(0.36)) }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var resultContent: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width * 0.72, 340)
            let cardHeight = min(cardWidth * 1.38, max(250, proxy.size.height - 250))

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("Here’s your\nlucky wallpaper ✨")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Text("Swipe to explore all 4 variations ✨\nor tap any card to view fullscreen.")
                        .font(.system(size: 14, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(WallpaperPalette.mutedText)
                }
                .padding(.top, 6)

                TabView(
                    selection: Binding(
                        get: { store.selectedIndex },
                        set: { store.send(.itemSelected($0)) }
                    )
                ) {
                    ForEach(Array(store.history.enumerated()), id: \.element.id) { index, item in
                        Button {
                            store.send(.itemTapped(item))
                        } label: {
                            WallpaperArtwork(item: item)
                                .frame(width: cardWidth, height: cardHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .stroke(WallpaperPalette.gold.opacity(0.48), lineWidth: 1.5)
                                }
                                .shadow(color: .black.opacity(0.5), radius: 16, y: 10)
                        }
                        .buttonStyle(.plain)
                        .tag(index)
                        .accessibilityLabel("Mở hình nền \(index + 1)")
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: cardHeight + 12)

                pagination
                variations
                    .padding(.top, 11)

                Spacer(minLength: 6)

                HStack(spacing: 12) {
                    Button {
                        store.send(.tryAnotherTapped)
                    } label: {
                        Label("Try another", systemImage: "arrow.clockwise")
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(WallpaperPalette.secondaryGradient)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        if let item = store.activeItem { store.send(.saveTapped(item)) }
                    } label: {
                        HStack(spacing: 7) {
                            if store.isSaving {
                                ProgressView().tint(WallpaperPalette.deepPurple)
                            } else {
                                Image(systemName: "arrow.down.to.line")
                            }
                            Text(store.isSaving ? "Saving..." : "Save wallpaper")
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(WallpaperPalette.deepPurple)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(WallpaperPalette.goldGradient)
                        .clipShape(Capsule())
                        .shadow(color: Color(hexValue: 0xE4A039).opacity(0.45), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isSaving || store.activeItem == nil)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
        }
    }

    private var pagination: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< min(4, store.history.count), id: \.self) { index in
                Capsule()
                    .fill(index == store.selectedIndex ? Color.white : Color(hexValue: 0x8E69C4).opacity(0.42))
                    .frame(width: index == store.selectedIndex ? 22 : 7, height: 7)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.selectedIndex)
    }

    private var variations: some View {
        HStack(spacing: 12) {
            ForEach(Array(store.history.prefix(4).enumerated()), id: \.element.id) { index, item in
                Button {
                    store.send(.itemSelected(index))
                } label: {
                    WallpaperArtwork(item: item)
                        .frame(width: 44, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(index + 1)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(index == store.selectedIndex ? WallpaperPalette.deepPurple : .white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(index == store.selectedIndex ? WallpaperPalette.gold : WallpaperPalette.deepPurple.opacity(0.84))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(2)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    index == store.selectedIndex ? WallpaperPalette.gold : Color(hexValue: 0x8E69C4).opacity(0.38),
                                    lineWidth: index == store.selectedIndex ? 2 : 1.5
                                )
                        }
                        .scaleEffect(index == store.selectedIndex ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Chọn phiên bản \(index + 1)")
            }
        }
    }

    private func toast(_ message: String) -> some View {
        VStack {
            Text(message)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(WallpaperPalette.gold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(Color(hexValue: 0x130C21).opacity(0.97))
                .clipShape(Capsule())
                .overlay { Capsule().stroke(WallpaperPalette.gold) }
                .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                .padding(.horizontal, 20)
                .padding(.top, 62)
            Spacer()
        }
    }
}

struct WallpaperDetailView: View {
    @Bindable var store: StoreOf<WallpaperDetailFeature>

    var body: some View {
        ZStack {
            Color(hexValue: 0x0A0612).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Button {
                        store.send(.closeTapped)
                    } label: {
                        Label("Đóng", systemImage: "xmark")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(.white.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Button {
                        store.send(.saveTapped(store.item))
                    } label: {
                        HStack(spacing: 6) {
                            if store.isSaving { ProgressView().tint(WallpaperPalette.deepPurple) }
                            else { Image(systemName: "arrow.down.to.line") }
                            Text(store.isSaving ? "Đang lưu..." : "Lưu ảnh")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WallpaperPalette.deepPurple)
                        .padding(.horizontal, 15)
                        .frame(height: 38)
                        .background(WallpaperPalette.gold)
                        .clipShape(Capsule())
                    }
                    .disabled(store.isSaving)
                }

                WallpaperArtwork(item: store.item, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 7) {
                    Text("“\(store.item.affirmationVi)”")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .italic()
                        .foregroundStyle(WallpaperPalette.gold)
                        .multilineTextAlignment(.center)
                    Text(store.item.explanationVi)
                        .font(.system(size: 12.5, design: .rounded))
                        .foregroundStyle(Color(hexValue: 0xD1C7E2))
                        .multilineTextAlignment(.center)
                    Text("✦ \(store.item.styleName)  •  \(store.item.intentionName)")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(WallpaperPalette.mutedText)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(hexValue: 0x1E1233))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hexValue: 0x8E69C4).opacity(0.3))
                }
            }
            .padding(16)
        }
        .preferredColorScheme(.dark)
    }
}

struct WallpaperMenuView: View {
    let store: StoreOf<WallpaperMenuFeature>

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 5) {
                Text("Xưởng Hình Nền May Mắn")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Số chủ đạo \(store.lifePath) • Ngày cá nhân \(store.personalDay)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(WallpaperPalette.mutedText)
            }

            menuButton("Xem 24 Lá Bài Bản Mệnh", "Bản đồ năng lượng linh số Pythagoras", "rectangle.stack") {
                store.send(.numerologyCardsTapped)
            }
            menuButton("Thư viện hình nền đã tạo", "Xem lại \(store.historyCount) tác phẩm đã hoàn thành", "photo.on.rectangle.angled") {
                store.send(.libraryTapped)
            }
            menuButton("Tạo hình nền may mắn mới", "Nhập mong muốn và hòa vào năng lượng vũ trụ", "sparkles") {
                store.send(.createNewTapped)
            }

            Button("Đóng") { store.send(.closeTapped) }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(WallpaperPalette.gold)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hexValue: 0x1E1233).ignoresSafeArea())
    }

    private func menuButton(
        _ title: String,
        _ subtitle: String,
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(WallpaperPalette.gold)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundStyle(WallpaperPalette.mutedText)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hexValue: 0xC9B3E9))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 68)
            .background(Color(hexValue: 0x2B1947))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct WallpaperProfileView: View {
    @Bindable var store: StoreOf<WallpaperProfileFeature>

    var body: some View {
        VStack(spacing: 17) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hồ sơ tạo hình nền")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Chỉ dùng một hồ sơ cho mỗi lần tạo")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(WallpaperPalette.mutedText)
                }
                Spacer()
                Button { store.send(.closeTapped) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 25))
                        .foregroundStyle(WallpaperPalette.mutedText)
                }
            }

            profileField("Họ và tên", text: Binding(
                get: { store.fullName },
                set: { store.send(.fullNameChanged($0)) }
            ))
            profileField("Ngày sinh YYYY-MM-DD", text: Binding(
                get: { store.birthDate },
                set: { store.send(.birthDateChanged($0)) }
            ))

            Picker(
                "Giới tính",
                selection: Binding(
                    get: { store.gender },
                    set: { store.send(.genderChanged($0)) }
                )
            ) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.titleVi).tag(gender)
                }
            }
            .pickerStyle(.segmented)

            if store.isUsingFallback {
                Text("Hồ sơ này được giữ trong phiên hiện tại. Đồng bộ hồ sơ sẽ được nối khi slice Auth/Profile hoàn tất.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(WallpaperPalette.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let validation = store.validationMessage {
                Text(validation)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hexValue: 0xFCA5A5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Dùng hồ sơ này") { store.send(.applyTapped) }
                .buttonStyle(WallpaperGoldButtonStyle())
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hexValue: 0x1E1233).ignoresSafeArea())
    }

    private func profileField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            .tint(WallpaperPalette.gold)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color(hexValue: 0x2B1947))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hexValue: 0x8E69C4).opacity(0.42))
            }
    }
}

private struct WallpaperArtwork: View {
    let item: WallpaperItem
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let asset = item.bundledAssetName.flatMap(AppAsset.init(rawValue:)) {
                Image(appAsset: asset)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let url = URL(string: item.imageUrl) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    case .failure:
                        imagePlaceholder(systemName: "exclamationmark.triangle", text: "Không tải được ảnh", loading: false)
                    case .empty:
                        imagePlaceholder(systemName: "sparkles", text: "Đang tải hình nền…", loading: true)
                    @unknown default:
                        imagePlaceholder(systemName: "photo", text: "Đang chuẩn bị ảnh…", loading: true)
                    }
                }
            } else {
                imagePlaceholder(systemName: "photo", text: "Ảnh không hợp lệ", loading: false)
            }
        }
        .background(Color(hexValue: 0x170E28))
        .clipped()
    }

    private func imagePlaceholder(systemName: String, text: String, loading: Bool) -> some View {
        VStack(spacing: 9) {
            if loading { ProgressView().tint(WallpaperPalette.gold) }
            Image(systemName: systemName).foregroundStyle(WallpaperPalette.gold)
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(WallpaperPalette.mutedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MoonDecorationView: View {
    @State private var twinkle = false

    var body: some View {
        ZStack {
            Image(appAsset: .wallpaperMoon).resizable().scaledToFit().padding(6)
            Image(appAsset: .wallpaperStar)
                .resizable().scaledToFit().frame(width: 19, height: 19)
                .offset(x: -35, y: -33)
                .scaleEffect(twinkle ? 1.15 : 0.75)
                .opacity(twinkle ? 1 : 0.35)
            Image(appAsset: .wallpaperThreeStars)
                .resizable().scaledToFit().frame(width: 21, height: 21)
                .offset(x: 34, y: 31)
                .scaleEffect(twinkle ? 0.8 : 1.1)
                .opacity(twinkle ? 0.35 : 1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                twinkle.toggle()
            }
        }
    }
}

private struct FloatingCardStackView: View {
    @State private var floating = false

    var body: some View {
        ZStack {
            card(.wallpaperMockCard1, width: 140, height: 185, rotation: -9)
                .offset(x: -80, y: floating ? -74 : -60)
            card(.wallpaperMockCard2, width: 145, height: 195, rotation: 7)
                .offset(x: 82, y: floating ? -57 : -72)
            card(.wallpaperMockCard4, width: 135, height: 180, rotation: 8)
                .offset(x: 82, y: floating ? 105 : 91)
            card(.wallpaperMockCard3, width: 195, height: 250, rotation: -1.5)
                .scaleEffect(floating ? 1.03 : 0.98)
                .offset(y: floating ? 3 : -8)
            Image(appAsset: .wallpaperStar)
                .resizable().scaledToFit().frame(width: 32, height: 32)
                .offset(x: -138, y: 48)
                .opacity(floating ? 1 : 0.4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                floating.toggle()
            }
        }
    }

    private func card(
        _ asset: AppAsset,
        width: CGFloat,
        height: CGFloat,
        rotation: Double
    ) -> some View {
        Image(appAsset: asset)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1)) }
            .shadow(color: .black.opacity(0.5), radius: 14, y: 8)
            .rotationEffect(.degrees(rotation))
    }
}

private struct FloatingWallpaperCloudView: View {
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 0.18)) { context in
                let seconds = context.date.timeIntervalSinceReferenceDate
                let frame = Int(seconds / 0.18) % 6
                let progress = (seconds.truncatingRemainder(dividingBy: 22)) / 22
                let cloudWidth: CGFloat = 220

                Image(appAsset: .wallpaperCloudSprite)
                    .resizable()
                    .frame(width: cloudWidth * 6, height: cloudWidth * 2)
                    .offset(x: -CGFloat(frame) * cloudWidth)
                    .frame(width: cloudWidth, height: cloudWidth * 2, alignment: .leading)
                    .clipped()
                    .offset(
                        x: -cloudWidth + CGFloat(progress) * (proxy.size.width + cloudWidth + 24),
                        y: max(150, proxy.size.height * 0.23)
                    )
            }
        }
    }
}

private struct WallpaperGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(WallpaperPalette.deepPurple)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(WallpaperPalette.goldGradient)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private enum WallpaperPalette {
    static let background = Color(hexValue: 0x211438)
    static let deepPurple = Color(hexValue: 0x211438)
    static let gold = Color(hexValue: 0xF7CC6A)
    static let mutedText = Color(hexValue: 0xB6A6CE)
    static let goldGradient = LinearGradient(
        colors: [Color(hexValue: 0xFFE5A1), Color(hexValue: 0xF5B84E), Color(hexValue: 0xDF962F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let secondaryGradient = LinearGradient(
        colors: [Color(hexValue: 0x4A2D82), Color(hexValue: 0x30195F), Color(hexValue: 0x1D103F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private extension Color {
    init(hexValue: UInt32) {
        self.init(
            red: Double((hexValue >> 16) & 0xFF) / 255,
            green: Double((hexValue >> 8) & 0xFF) / 255,
            blue: Double(hexValue & 0xFF) / 255
        )
    }
}

#Preview("Wallpaper Input") {
    WallpaperView(
        store: Store(initialState: WallpaperFeature.State()) {
            WallpaperFeature()
        } withDependencies: {
            $0.wallpaperClient = .previewValue
            $0.hapticClient = .testValue
        }
    )
}
