import Foundation

// Structure to collect all onboarding answers for ChatGPT integration
struct OnboardingAnswers {
    let age: String
    let sex: String
    let activityLevel: String
    let hydrationLevel: String
    let skincareGoal: String
    let skinConditions: String
    
    var asDictionary: [String: String] {
        return [
            "age": age,
            "sex": sex,
            "activity_level": activityLevel,
            "hydration_level": hydrationLevel,
            "skincare_goal": skincareGoal,
            "skin_conditions": skinConditions
        ]
    }
    
    var asFormattedString: String {
        return """
        User Profile:
        - Age: \(age)
        - Sex: \(sex)
        - Activity Level: \(activityLevel)
        - Hydration Level: \(hydrationLevel)
        - Skincare Goal: \(skincareGoal)
        - Skin Conditions: \(skinConditions)
        """
    }
    
    // Static function to create from array of answers
    static func fromAnswers(_ answers: [String]) -> OnboardingAnswers? {
        guard answers.count >= 6, answers.allSatisfy({ !$0.isEmpty }) else {
            return nil
        }
        
        return OnboardingAnswers(
            age: answers[0],
            sex: answers[1],
            activityLevel: answers[2],
            hydrationLevel: answers[3],
            skincareGoal: answers[4],
            skinConditions: answers[5]
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