import Foundation
import UIKit
import FirebaseStorage

class SkinAnalysisManager: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResults: SkinAnalysisResult?
    @Published var uploadedImages: [UIImage] = []
    @Published var recommendations: SkincareRecommendations?
    @Published var errorMessage: String?
    
    private let storage = Storage.storage()
    private let apiBaseURL = "https://your-fastapi-backend.com"
    
    func uploadImages(_ images: [UIImage]) {
        isAnalyzing = true
        errorMessage = nil
        uploadedImages = images
        
        uploadImagesToStorage(images) { [weak self] imageURLs in
            self?.analyzeSkinConditions(imageURLs: imageURLs)
        }
    }
    
    private func uploadImagesToStorage(_ images: [UIImage], completion: @escaping ([String]) -> Void) {
        let group = DispatchGroup()
        var imageURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            group.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                group.leave()
                continue
            }
            
            let imageName = "skin_analysis_$(Date().timeIntervalSince1970)_$(index).jpg"
            let storageRef = storage.reference().child("skin_analysis/$(imageName)")
            
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to upload image: $(error.localizedDescription)"
                    }
                    group.leave()
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let url = url {
                        imageURLs.append(url.absoluteString)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(imageURLs)
        }
    }
    
    private func analyzeSkinConditions(imageURLs: [String]) {
        guard let url = URL(string: "$(apiBaseURL)/analyze-skin") else {
            isAnalyzing = false
            errorMessage = "Invalid API URL"
            return
        }
        
        let requestData = SkinAnalysisRequest(
            imageURLs: imageURLs,
            userProfile: getUserProfile()
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            isAnalyzing = false
            errorMessage = "Failed to encode request data"
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(SkinAnalysisResult.self, from: data)
                    self?.analysisResults = result
                    self?.generateRecommendations(result: result)
                } catch {
                    self?.errorMessage = "Failed to decode response: $(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func generateRecommendations(result: SkinAnalysisResult) {
        guard let url = URL(string: "$(apiBaseURL)/generate-recommendations") else {
            errorMessage = "Invalid API URL"
            return
        }
        
        let requestData = RecommendationRequest(
            skinConditions: result.conditions,
            userProfile: getUserProfile(),
            weatherData: getWeatherData()
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            errorMessage = "Failed to encode request data"
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let recommendations = try JSONDecoder().decode(SkincareRecommendations.self, from: data)
                    self?.recommendations = recommendations
                } catch {
                    self?.errorMessage = "Failed to decode recommendations: $(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func getUserProfile() -> UserProfile {
        return UserProfile(
            age: 25,
            gender: "female",
            skinType: "combination",
            race: "asian",
            location: "San Francisco, CA"
        )
    }
    
    private func getWeatherData() -> WeatherData? {
        return WeatherData(
            temperature: 22.0,
            humidity: 65.0,
            uvIndex: 5.0
        )
    }
}
