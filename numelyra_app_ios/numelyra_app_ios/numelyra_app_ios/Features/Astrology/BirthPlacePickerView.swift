import ComposableArchitecture
import SwiftUI

struct BirthPlacePickerView: View {
    @Bindable var store: StoreOf<BirthPlacePickerFeature>

    var body: some View {
        VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nơi sinh")
                        .font(.title2.bold())
                    Text("Tìm thành phố hoặc khu vực nơi bạn sinh ra. Ứng dụng không dùng GPS.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField(
                    "Ví dụ: Hà Nội",
                    text: Binding(
                        get: { store.query },
                        set: { store.send(.queryChanged($0)) }
                    )
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

                if store.isSearching || store.isResolving {
                    ProgressView(store.isResolving ? "Đang xác nhận múi giờ…" : "Đang tìm…")
                }

                if let message = store.errorMessage {
                    VStack(spacing: 8) {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                        Button("Thử lại") { store.send(.retryTapped) }
                    }
                }

                List(store.suggestions) { suggestion in
                    Button {
                        store.send(.suggestionTapped(suggestion))
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(suggestion.primaryText)
                                .foregroundStyle(.primary)
                            if let secondary = suggestion.secondaryText {
                                Text(secondary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(store.isResolving)
                }
                .listStyle(.plain)

                Button("Bỏ qua lúc này") { store.send(.skipTapped) }
                    .buttonStyle(.borderless)
            }
            .padding()
            .task { store.send(.onAppear) }
    }
}

#Preview {
    BirthPlacePickerView(
        store: Store(initialState: BirthPlacePickerFeature.State()) {
            BirthPlacePickerFeature()
        } withDependencies: {
            $0.birthLocationClient = .previewValue
        }
    )
}
