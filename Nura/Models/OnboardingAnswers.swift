import Foundation

// Structure to collect all onboarding answers for ChatGPT integration
struct OnboardingAnswers {
    var age: String
    var sex: String
    var activityLevel: String
    var hydrationLevel: String
    var skincareGoal: String
    var skinConditions: String
    var dermatologistStatus: String
    var healthConditions: String
    var smokingStatus: String
    var sleepQuality: String
    // Optional reproductive health fields (for female users). Only persisted if set
    var periodCycleInfo: String? = nil
    var birthControlInfo: String? = nil
    
    var asDictionary: [String: String] {
        var dict: [String: String] = [
            "age": age,
            "sex": sex,
            "activity_level": activityLevel,
            "hydration_level": hydrationLevel,
            "skincare_goal": skincareGoal,
            "skin_conditions": skinConditions,
            "dermatologist_status": dermatologistStatus,
            "health_conditions": healthConditions,
            "smoking_status": smokingStatus,
            "sleep_quality": sleepQuality
        ]
        if let period = periodCycleInfo, !period.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dict["period_cycle_info"] = period
        }
        if let pills = birthControlInfo, !pills.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dict["birth_control_info"] = pills
        }
        return dict
    }
    
    var asFormattedString: String {
        var base = """
        User Profile:
        - Age: \(age)
        - Sex: \(sex)
        - Activity Level: \(activityLevel)
        - Hydration Level: \(hydrationLevel)
        - Skincare Goal: \(skincareGoal)
        - Skin Conditions: \(skinConditions)
        - Dermatologist: \(dermatologistStatus)
        - Health Conditions: \(healthConditions)
        - Smoking: \(smokingStatus)
        - Sleep: \(sleepQuality)
        """
        if let period = periodCycleInfo, !period.isEmpty {
            base += "\n        - Period/Cycle: \(period)"
        }
        if let pills = birthControlInfo, !pills.isEmpty {
            base += "\n        - Birth Control: \(pills)"
        }
        return base
    }
    
    // Static function to create from array of answers
    static func fromAnswers(_ answers: [String]) -> OnboardingAnswers? {
        guard answers.count >= 10, answers.prefix(10).allSatisfy({ !$0.isEmpty }) else {
            return nil
        }
        
        return OnboardingAnswers(
            age: answers[0],
            sex: answers[1],
            activityLevel: answers[2],
            hydrationLevel: answers[3],
            skincareGoal: answers[4],
            skinConditions: answers[5],
            dermatologistStatus: answers[6],
            healthConditions: answers[7],
            smokingStatus: answers[8],
            sleepQuality: answers[9]
        )
    }
    
    // Function to create ChatGPT prompt context
    var asChatGPTPrompt: String {
        return """
        Based on the following user profile, provide personalized skincare advice:
        
        \(asFormattedString)
        
        Please provide specific, actionable skincare recommendations tailored to this user's profile.
        """
    }
} 