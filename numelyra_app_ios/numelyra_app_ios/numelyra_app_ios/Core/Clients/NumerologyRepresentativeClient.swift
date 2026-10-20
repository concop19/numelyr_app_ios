import ComposableArchitecture
import Foundation
import UIKit

@DependencyClient
public struct NumerologyRepresentativeClient: Sendable {
    public var findByTriple: @Sendable (_ triple: RepresentativeTriple) async throws -> NumerologyRepresentative?
    public var loadImage: @Sendable (_ url: URL) async throws -> Data
    public var openSource: @Sendable (_ url: URL) async -> Bool = { _ in false }
}

extension NumerologyRepresentativeClient: DependencyKey {
    public static let liveValue = Self(
        findByTriple: { triple in
            try NumerologyRepresentativeService.representative(matching: triple)
        },
        loadImage: { url in
            let (data, response) = try await URLSession.shared.data(from: url)
            if let response = response as? HTTPURLResponse,
               !(200...299).contains(response.statusCode) {
                throw RepresentativeLookupError.invalidImageResponse
            }
            guard !data.isEmpty else { throw RepresentativeLookupError.invalidImageResponse }
            return data
        },
        openSource: { url in
            await MainActor.run {
                UIApplication.shared.open(url)
                return true
            }
        }
    )

    public static let previewValue = Self(
        findByTriple: { _ in nil },
        loadImage: { _ in throw RepresentativeLookupError.invalidImageResponse },
        openSource: { _ in true }
    )

    public static let testValue = Self()
}

public extension DependencyValues {
    var numerologyRepresentativeClient: NumerologyRepresentativeClient {
        get { self[NumerologyRepresentativeClient.self] }
        set { self[NumerologyRepresentativeClient.self] = newValue }
    }
}
