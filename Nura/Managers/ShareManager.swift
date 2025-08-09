import SwiftUI
import UIKit
import Social
import MessageUI

@MainActor
class ShareManager: ObservableObject {
    @Published var isShowingShareSheet = false
    @Published var isShowingInstagramShare = false
    @Published var isShowingSnapchatShare = false
    @Published var isShowingTextShare = false
    
    private var shareImage: UIImage?
    private var shareText: String = ""
    
    // MARK: - Share Methods
    
    func shareSkinAnalysisResult(analysis: SkinAnalysisResult, skinScore: Double) {
        let image = generateShareImage(analysis: analysis, skinScore: skinScore)
        let text = generateShareText(analysis: analysis, skinScore: skinScore)
        
        self.shareImage = image
        self.shareText = text
        self.isShowingShareSheet = true
    }
    
    func shareToInstagram() {
        guard let image = shareImage else { return }
        
        // Instagram sharing via URL scheme
        if let instagramURL = URL(string: "instagram://app") {
            if UIApplication.shared.canOpenURL(instagramURL) {
                // Save image to photos and open Instagram
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                // Instagram not installed, show App Store
                if let appStoreURL = URL(string: "https://apps.apple.com/app/instagram/id389801252") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
    
    func shareToSnapchat() {
        guard let image = shareImage else { return }
        
        // Snapchat sharing via URL scheme
        if let snapchatURL = URL(string: "snapchat://") {
            if UIApplication.shared.canOpenURL(snapchatURL) {
                // Save image to photos and open Snapchat
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                // Snapchat not installed, show App Store
                if let appStoreURL = URL(string: "https://apps.apple.com/app/snapchat/id447188370") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
    
    func shareToText() {
        guard let image = shareImage, let text = shareText.isEmpty ? nil : shareText else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            if let presenter = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = window
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                presenter.present(activityVC, animated: true)
            }
        }
    }
    
    // MARK: - Image Generation
    
    private func generateShareImage(analysis: SkinAnalysisResult, skinScore: Double) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: 1920))
        
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: 1080, height: 1920)
            
            // Background gradient
            let gradient = CAGradientLayer()
            gradient.frame = rect
            gradient.colors = [
                UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0).cgColor,
                UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
            gradient.render(in: context.cgContext)
            
            // Nura logo/branding
            let logoText = "Nura"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .light),
                .foregroundColor: UIColor.white
            ]
            let logoSize = logoText.size(withAttributes: logoAttributes)
            let logoRect = CGRect(x: (rect.width - logoSize.width) / 2, y: 100, width: logoSize.width, height: logoSize.height)
            logoText.draw(in: logoRect, withAttributes: logoAttributes)
            
            // Skin Score
            let scoreText = "Skin Score:"
            let scoreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let scoreSize = scoreText.size(withAttributes: scoreAttributes)
            let scoreRect = CGRect(x: (rect.width - scoreSize.width) / 2, y: 300, width: scoreSize.width, height: scoreSize.height)
            scoreText.draw(in: scoreRect, withAttributes: scoreAttributes)
            
            // Score Value
            let scoreValueText = String(format: "%.1f", skinScore)
            let scoreValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let scoreValueSize = scoreValueText.size(withAttributes: scoreValueAttributes)
            let scoreValueRect = CGRect(x: (rect.width - scoreValueSize.width) / 2, y: 350, width: scoreValueSize.width, height: scoreValueSize.height)
            scoreValueText.draw(in: scoreValueRect, withAttributes: scoreValueAttributes)
            
            // Motivational message
            let messageText = getMotivationalMessage(for: skinScore)
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let messageSize = messageText.size(withAttributes: messageAttributes)
            let messageRect = CGRect(x: (rect.width - messageSize.width) / 2, y: 500, width: messageSize.width, height: messageSize.height)
            messageText.draw(in: messageRect, withAttributes: messageAttributes)
            
            // Analysis details
            let detailsText = "Analysis Results:"
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let detailsSize = detailsText.size(withAttributes: detailsAttributes)
            let detailsRect = CGRect(x: 100, y: 700, width: detailsSize.width, height: detailsSize.height)
            detailsText.draw(in: detailsRect, withAttributes: detailsAttributes)
            
            // Conditions
            var yOffset: CGFloat = 750
            for condition in analysis.conditions.prefix(3) {
                let conditionText = "• \(condition.name.capitalized) (\(condition.severity.rawValue.capitalized))"
                let conditionAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                    .foregroundColor: UIColor.white
                ]
                let conditionSize = conditionText.size(withAttributes: conditionAttributes)
                let conditionRect = CGRect(x: 120, y: yOffset, width: conditionSize.width, height: conditionSize.height)
                conditionText.draw(in: conditionRect, withAttributes: conditionAttributes)
                yOffset += 40
            }
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateText = dateFormatter.string(from: analysis.analysisDate)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let dateSize = dateText.size(withAttributes: dateAttributes)
            let dateRect = CGRect(x: (rect.width - dateSize.width) / 2, y: rect.height - 150, width: dateSize.width, height: dateSize.height)
            dateText.draw(in: dateRect, withAttributes: dateAttributes)
            
            // Download Nura text
            let downloadText = "Download Nura for your skin journey"
            let downloadAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            let downloadSize = downloadText.size(withAttributes: downloadAttributes)
            let downloadRect = CGRect(x: (rect.width - downloadSize.width) / 2, y: rect.height - 100, width: downloadSize.width, height: downloadSize.height)
            downloadText.draw(in: downloadRect, withAttributes: downloadAttributes)
        }
    }
    
    private func generateShareText(analysis: SkinAnalysisResult, skinScore: Double) -> String {
        let scoreText = String(format: "%.1f", skinScore)
        let message = getMotivationalMessage(for: skinScore)
        
        var text = "✨ My Nura Skin Score: \(scoreText)/10\n"
        text += "\"\(message)\"\n\n"
        
        if !analysis.conditions.isEmpty {
            text += "Analysis Results:\n"
            for condition in analysis.conditions.prefix(3) {
                text += "• \(condition.name.capitalized) (\(condition.severity.rawValue.capitalized))\n"
            }
        }
        
        text += "\n📱 Download Nura for your skin journey!"
        
        return text
    }
    
    private func getMotivationalMessage(for score: Double) -> String {
        switch score {
        case 8.0...10.0:
            return "Your glow is next level today! ✨"
        case 6.0..<8.0:
            return "Great progress on your skin journey! 🌟"
        case 4.0..<6.0:
            return "Every step counts towards healthy skin! 💪"
        default:
            return "Your skin journey starts here! 🌱"
        }
    }
    
    // MARK: - Image Save Callback
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image saved successfully")
            // The image is now in the photo library and can be shared via Instagram/Snapchat
        }
    }
}

// MARK: - Share Sheet View

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 