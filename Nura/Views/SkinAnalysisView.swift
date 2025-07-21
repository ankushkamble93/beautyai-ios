import SwiftUI
import PhotosUI

struct SkinAnalysisView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Skin Analysis")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Upload 3 selfies from different angles for AI-powered skin analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Image upload section
                    VStack(spacing: 20) {
                        if skinAnalysisManager.uploadedImages.isEmpty {
                            // Upload prompt
                            VStack(spacing: 15) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                
                                Text("Upload 3 Selfies")
                                    .font(.headline)
                                
                                Text("Front, left side, and right side views for best results")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                            )
                        } else {
                            // Uploaded images
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                                ForEach(Array(skinAnalysisManager.uploadedImages.enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.purple, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        
                        // Upload button
                        PhotosPicker(selection: $selectedImages, maxSelectionCount: 3, matching: .images) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Select Photos")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .onChange(of: selectedImages) { items in
                            Task {
                                await loadImages(from: items)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Analysis button
                    if !skinAnalysisManager.uploadedImages.isEmpty {
                        Button(action: {
                            skinAnalysisManager.uploadImages(skinAnalysisManager.uploadedImages)
                        }) {
                            HStack {
                                if skinAnalysisManager.isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                
                                Text(skinAnalysisManager.isAnalyzing ? "Analyzing..." : "Analyze Skin")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(skinAnalysisManager.isAnalyzing)
                        .padding(.horizontal)
                    }
                    
                    // Error message
                    if let errorMessage = skinAnalysisManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Results section
                    if let results = skinAnalysisManager.analysisResults {
                        AnalysisResultsView(results: results)
                    }
                    
                    // Recommendations section
                    if let recommendations = skinAnalysisManager.recommendations {
                        RecommendationsView(recommendations: recommendations)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Skin Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var loadedImages: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
            }
        }
        
        DispatchQueue.main.async {
            skinAnalysisManager.uploadedImages = loadedImages
        }
    }
}

struct AnalysisResultsView: View {
    let results: SkinAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Analysis Results")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                ForEach(results.conditions) { condition in
                    ConditionCard(condition: condition)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ConditionCard: View {
    let condition: SkinCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(condition.name.capitalized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(condition.severity.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(8)
            }
            
            Text(condition.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !condition.affectedAreas.isEmpty {
                Text("Affected areas: \(condition.affectedAreas.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Confidence: \(Int(condition.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: condition.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    .frame(width: 60)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var severityColor: Color {
        switch condition.severity {
        case .mild: return .green
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct RecommendationsView: View {
    let recommendations: SkincareRecommendations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personalized Recommendations")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Morning routine
            RoutineSection(title: "Morning Routine", steps: recommendations.morningRoutine)
            
            // Evening routine
            RoutineSection(title: "Evening Routine", steps: recommendations.eveningRoutine)
            
            // Weekly treatments
            if !recommendations.weeklyTreatments.isEmpty {
                RoutineSection(title: "Weekly Treatments", steps: recommendations.weeklyTreatments)
            }
            
            // Lifestyle tips
            if !recommendations.lifestyleTips.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Lifestyle Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(recommendations.lifestyleTips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(tip)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct RoutineSection: View {
    let title: String
    let steps: [SkincareStep]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(steps) { step in
                StepCard(step: step)
            }
        }
    }
}

struct StepCard: View {
    let step: SkincareStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(step.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(step.frequency.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(6)
            }
            
            Text(step.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !step.tips.isEmpty {
                Text("💡 \(step.tips.first ?? "")")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    SkinAnalysisView()
        .environmentObject(SkinAnalysisManager())
} 