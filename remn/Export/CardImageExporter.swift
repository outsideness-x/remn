import Photos
import SwiftUI

enum CardImageExportError: LocalizedError {
    case renderingFailed
    case photoAccessDenied

    var errorDescription: String? {
        switch self {
        case .renderingFailed: RemnLanguage.localized("export.renderFailed")
        case .photoAccessDenied: RemnLanguage.localized("export.photosDenied")
        }
    }
}

@MainActor
enum CardImageExporter {
    static func save(_ card: Flashcard) async throws {
        let renderer = ImageRenderer(content: CardExportView(card: card))
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: 540, height: nil)
        guard let image = renderer.uiImage else {
            throw CardImageExportError.renderingFailed
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw CardImageExportError.photoAccessDenied
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if let error { continuation.resume(throwing: error) }
                else if success { continuation.resume() }
                else { continuation.resume(throwing: CardImageExportError.renderingFailed) }
            }
        }
    }
}
