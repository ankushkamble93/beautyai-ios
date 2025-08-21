import Foundation
import SwiftUI

final class ImageCache {
    static let shared = ImageCache()
    private init() {}
    private let cache = NSCache<NSString, UIImage>()
    
    func image(forKey key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func set(_ image: UIImage, forKey key: String) { cache.setObject(image, forKey: key as NSString) }
}

@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading: Bool = false
    
    func load(from urlString: String?) async {
        guard let urlString, let url = URL(string: urlString) else { return }
        if let cached = ImageCache.shared.image(forKey: urlString) {
            self.image = cached
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                ImageCache.shared.set(img, forKey: urlString)
                self.image = img
            }
        } catch {
            // Ignore failures; keep placeholder
        }
    }
}


