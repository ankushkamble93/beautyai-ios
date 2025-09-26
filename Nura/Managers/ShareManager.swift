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
    
    func prepareSharePayload(analysis: SkinAnalysisResult, skinScore: Double) {
        let image = generateShareImage(analysis: analysis, skinScore: skinScore)
        let text = generateShareText(analysis: analysis, skinScore: skinScore)
        self.shareImage = image
        self.shareText = text
    }

    func shareSkinAnalysisResult(analysis: SkinAnalysisResult, skinScore: Double) {
        prepareSharePayload(analysis: analysis, skinScore: skinScore)
        self.isShowingShareSheet = true
    }
    
    func shareToInstagram() {
        guard let image = shareImage else { return }
        
        // Prefer Instagram Stories share if available
        let storiesURL = URL(string: "instagram-stories://share")!
        if UIApplication.shared.canOpenURL(storiesURL), let png = image.pngData() {
            let pasteboardItems: [[String: Any]] = [[
                "com.instagram.sharedSticker.backgroundImage": png
            ]]
            UIPasteboard.general.setItems(pasteboardItems, options: [
                UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)
            ])
            UIApplication.shared.open(storiesURL)
            return
        }
        // Fallback: open Instagram app so the user can post from library
        if let appURL = URL(string: "instagram://app"), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let appStoreURL = URL(string: "https://apps.apple.com/app/instagram/id389801252") {
            UIApplication.shared.open(appStoreURL)
        }
    }
    
    func shareToSnapchat() {
        guard let image = shareImage else { return }
        
        // Attempt Creative Kit pasteboard share (best-effort without SDK)
        if let png = image.pngData(), let creativeURL = URL(string: "snapchat://creativeKit/share"), UIApplication.shared.canOpenURL(creativeURL) {
            let items: [[String: Any]] = [[
                "com.snapchat.creativeKit.sticker": png
            ]]
            UIPasteboard.general.setItems(items, options: [
                UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)
            ])
            UIApplication.shared.open(creativeURL)
            return
        }
        // Fallback: open camera and let user choose image from Photos
        if let cameraURL = URL(string: "snapchat://camera"), UIApplication.shared.canOpenURL(cameraURL) {
            UIApplication.shared.open(cameraURL)
        } else if let appStoreURL = URL(string: "https://apps.apple.com/app/snapchat/id447188370") {
            UIApplication.shared.open(appStoreURL)
        }
    }
    
    func shareToText() {
        // Ensure payload prepared
        if shareImage == nil || shareText.isEmpty {
            // Provide a default composed card to avoid no-op
            let fallback = SkinAnalysisResult(
                conditions: [],
                confidence: 0.9,
                analysisDate: Date(),
                recommendations: [],
                skinHealthScore: 80,
                analysisVersion: "1.0",
                routineGenerationTimestamp: nil,
                analysisProvider: .mock,
                imageCount: 0,
                skinAgeYears: nil
            )
            self.prepareSharePayload(analysis: fallback, skinScore: 8.0)
        }
        guard let image = shareImage else { return }
        let items: [Any] = shareText.isEmpty ? [image] : [image, shareText]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList, .print]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let presenter = window.rootViewController {
            if let pop = activityVC.popoverPresentationController {
                pop.sourceView = window
                pop.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            presenter.present(activityVC, animated: true)
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

            // Soft vignette overlay for depth
            let vignette = UIBezierPath(rect: rect)
            UIColor.black.withAlphaComponent(0.15).setFill()
            vignette.fill()
            
            // Nura logo/branding
            let logoText = "Nura"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .light),
                .foregroundColor: UIColor.white
            ]
            let logoSize = logoText.size(withAttributes: logoAttributes)
            let logoRect = CGRect(x: (rect.width - logoSize.width) / 2, y: 100, width: logoSize.width, height: logoSize.height)
            logoText.draw(in: logoRect, withAttributes: logoAttributes)
            
            // Score ring like Strava stat card
            let center = CGPoint(x: rect.midX, y: 420)
            let radius: CGFloat = 150
            let ringBackground = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi/2, endAngle: 1.5 * .pi, clockwise: true)
            UIColor.white.withAlphaComponent(0.2).setStroke()
            ringBackground.lineWidth = 24
            ringBackground.stroke()

            let progress = max(0.0, min(1.0, skinScore / 10.0))
            let endAngle = (-.pi/2) + (2 * .pi * progress)
            let ringPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi/2, endAngle: endAngle, clockwise: true)
            UIColor(red: 0.95, green: 0.75, blue: 0.35, alpha: 1.0).setStroke()
            ringPath.lineWidth = 24
            ringPath.lineCapStyle = .round
            ringPath.stroke()

            // Score value in the middle
            let scoreValueText = String(format: "%.1f", skinScore)
            let scoreValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let scoreValueSize = scoreValueText.size(withAttributes: scoreValueAttributes)
            let scoreValueRect = CGRect(x: center.x - scoreValueSize.width/2, y: center.y - scoreValueSize.height/2 - 10, width: scoreValueSize.width, height: scoreValueSize.height)
            scoreValueText.draw(in: scoreValueRect, withAttributes: scoreValueAttributes)

            let outOfText = "out of 10"
            let outOfAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ]
            let outOfSize = outOfText.size(withAttributes: outOfAttributes)
            let outOfRect = CGRect(x: center.x - outOfSize.width/2, y: center.y + scoreValueSize.height/2 - 4, width: outOfSize.width, height: outOfSize.height)
            outOfText.draw(in: outOfRect, withAttributes: outOfAttributes)
            
            // Motivational message
            let messageText = getMotivationalMessage(for: skinScore)
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let messageSize = messageText.size(withAttributes: messageAttributes)
            let messageRect = CGRect(x: (rect.width - messageSize.width) / 2, y: 620, width: messageSize.width, height: messageSize.height)
            messageText.draw(in: messageRect, withAttributes: messageAttributes)
            
            // Analysis details
            let detailsText = "Analysis Results:"
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let detailsSize = detailsText.size(withAttributes: detailsAttributes)
            let detailsRect = CGRect(x: 100, y: 760, width: detailsSize.width, height: detailsSize.height)
            detailsText.draw(in: detailsRect, withAttributes: detailsAttributes)
            
            // Conditions
            var yOffset: CGFloat = 810
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