import ComposableArchitecture
import Foundation

@Reducer
struct HistoricalFigureFeature {
    enum Phase: Equatable {
        case loading
        case loaded
        case empty
        case failed(String)
    }

    @ObservableState
    struct State: Equatable {
        var triple: RepresentativeTriple
        var phase: Phase = .loading
        var figure: NumerologyRepresentative?
        var imageData: Data?
        var isImageLoading = false
        var language: RepresentativeLanguage = .vietnamese
        var isBiographyExpanded = false
        var shareText: String?

        init(triple: RepresentativeTriple) {
            self.triple = triple
        }

        var displayName: String {
            figure?.displayName(for: language) ?? "Nhân Vật Lịch Sử"
        }

        var biography: String {
            figure?.biography(for: language) ?? ""
        }

        var originalName: String? {
            guard language == .vietnamese,
                  let figure,
                  let vietnameseName = figure.displayNameVi?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !vietnameseName.isEmpty,
                  vietnameseName != figure.displayName
            else { return nil }
            return figure.displayName
        }
    }

    enum Action: Equatable {
        case onAppear
        case retryTapped
        case lookupResponse(Result<NumerologyRepresentative?, RepresentativeLookupError>)
        case imageResponse(Result<Data, RepresentativeLookupError>)
        case languageSelected(RepresentativeLanguage)
        case toggleBiographyTapped
        case shareTapped
        case shareDismissed
        case openSourceTapped
        case closeTapped
    }

    private nonisolated enum CancelID: Hashable, Sendable { case lookup, image }

    @Dependency(\.numerologyRepresentativeClient) var representativeClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.figure == nil else { return .none }
                return lookup(&state)

            case .retryTapped:
                return lookup(&state)

            case let .lookupResponse(.success(figure)):
                state.figure = figure
                guard let figure else {
                    state.phase = .empty
                    return .none
                }
                state.phase = .loaded
                guard let rawURL = figure.imageURL,
                      let url = URL(string: rawURL)
                else { return .none }
                state.isImageLoading = true
                return .run { send in
                    do {
                        await send(.imageResponse(.success(try await representativeClient.loadImage(url))))
                    } catch let error as RepresentativeLookupError {
                        await send(.imageResponse(.failure(error)))
                    } catch {
                        await send(.imageResponse(.failure(.invalidImageResponse)))
                    }
                }
                .cancellable(id: CancelID.image, cancelInFlight: true)

            case let .lookupResponse(.failure(error)):
                state.phase = .failed(error.messageVi)
                return .none

            case let .imageResponse(.success(data)):
                state.imageData = data
                state.isImageLoading = false
                return .none

            case .imageResponse(.failure):
                state.imageData = nil
                state.isImageLoading = false
                return .none

            case let .languageSelected(language):
                guard state.language != language else { return .none }
                state.language = language
                state.isBiographyExpanded = false
                return .run { _ in await hapticClient.selection() }

            case .toggleBiographyTapped:
                state.isBiographyExpanded.toggle()
                return .run { _ in await hapticClient.selection() }

            case .shareTapped:
                guard let figure = state.figure else { return .none }
                state.shareText = """
                ✦ Nhân vật đồng điệu Thần số học với tôi: \(state.displayName) (\(figure.lifespan))
                Bộ 3 số cốt lõi: Đường đời \(figure.lifePath) · Sứ mệnh \(figure.expression) · Linh hồn \(figure.soulUrge).
                Khám phá hành trình cùng Numelyra!
                """
                return .run { _ in await hapticClient.selection() }

            case .shareDismissed:
                state.shareText = nil
                return .none

            case .openSourceTapped:
                guard let url = state.figure?.sourceURL else { return .none }
                return .run { _ in
                    await hapticClient.lightImpact()
                    _ = await representativeClient.openSource(url)
                }

            case .closeTapped:
                return .run { _ in await dismiss() }
            }
        }
    }

    private func lookup(_ state: inout State) -> Effect<Action> {
        state.phase = .loading
        state.figure = nil
        state.imageData = nil
        state.isImageLoading = false
        let triple = state.triple
        return .run { send in
            do {
                await send(.lookupResponse(.success(try await representativeClient.findByTriple(triple))))
            } catch let error as RepresentativeLookupError {
                await send(.lookupResponse(.failure(error)))
            } catch {
                await send(.lookupResponse(.failure(.queryFailed(error.localizedDescription))))
            }
        }
        .cancellable(id: CancelID.lookup, cancelInFlight: true)
    }
}
