# BeautyAI iOS App

A mobile-first iOS app that helps users track and improve their skin health using AI-powered analysis and personalized recommendations.

## Features

### 🧠 AI-Powered Skin Analysis
- Upload 3 selfies from different angles
- AI detects skin conditions (acne, dryness, oiliness, hyperpigmentation, etc.)
- Uses image analysis APIs (Replicate/HuggingFace) for accurate detection

### 💡 Personalized Recommendations
- Customized skincare routines (morning + evening)
- Based on user profile: age, gender, skin type, race, location
- Weather and humidity integration
- Wearables data integration (Apple Watch activity, sleep quality)

### 🤖 AI Chat Assistant
- GPT-4o powered skin assistant
- Discuss concerns and get personalized advice
- Context-aware conversations based on user profile

### 📊 Progress Dashboard
- Track skin health improvements over time
- Visual progress metrics and insights
- Routine completion tracking
- Weather-based recommendations

### 💳 Monetization
- Stripe integration for premium features
- Subscription tiers for advanced advice and routines
- Product recommendations and affiliate links

## Tech Stack

### Frontend
- **SwiftUI** - Modern iOS UI framework
- **iOS 17.0+** - Latest iOS features and APIs
- **PhotosUI** - Image picker and camera integration
- **HealthKit** - Apple Watch data integration

### Backend Integration
- **FastAPI** - Python backend for AI processing
- **Firebase** - Authentication and storage
- **Stripe** - Payment processing
- **Replicate/HuggingFace** - AI image analysis

### AI & ML
- **GPT-4o** - Chat assistant
- **Computer Vision** - Skin condition detection
- **Recommendation Engine** - Personalized skincare routines

## Project Structure

```
BeautyAI/
├── BeautyAIApp.swift              # Main app entry point
├── ContentView.swift              # Root view with tab navigation
├── Models/
│   └── DataModels.swift           # All data models and structures
├── Managers/
│   ├── AuthenticationManager.swift # Firebase auth
│   ├── SkinAnalysisManager.swift  # AI analysis handling
│   └── ChatManager.swift          # GPT-4o chat
├── Views/
│   ├── AuthenticationView.swift   # Login/signup
│   ├── DashboardView.swift        # Main dashboard
│   ├── SkinAnalysisView.swift     # Photo upload & analysis
│   ├── ChatView.swift             # AI chat interface
│   └── ProfileView.swift          # User profile & settings
├── Assets.xcassets/               # App icons and images
└── GoogleService-Info.plist       # Firebase configuration
```

## Setup Instructions

### Prerequisites
1. **Xcode 15.0+** - Download from Mac App Store
2. **iOS 17.0+** - For development and testing
3. **Firebase Account** - For authentication and storage
4. **FastAPI Backend** - For AI processing (separate repository)

### Installation

1. **Clone the repository**
   ```bash
   git clone git@github.com:ankushkamble93/beautyai-ios.git
   cd beautyai-ios
   ```

2. **Open in Xcode**
   ```bash
   open BeautyAI.xcodeproj
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add iOS app with bundle ID: `com.beautyai.ios`
   - Download `GoogleService-Info.plist` and replace the placeholder
   - Enable Authentication (Email/Password)
   - Enable Storage for image uploads

4. **Configure Backend URL**
   - Update `apiBaseURL` in `SkinAnalysisManager.swift` and `ChatManager.swift`
   - Replace `"https://your-fastapi-backend.com"` with your actual backend URL

5. **Add Dependencies**
   - Firebase SDK (via Swift Package Manager)
   - Stripe SDK (for payments)
   - Any additional AI/ML libraries

6. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Environment Configuration

Create a `.env` file or use Xcode's configuration:
```bash
# Firebase
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id

# Backend
API_BASE_URL=https://your-fastapi-backend.com

# Stripe
STRIPE_PUBLISHABLE_KEY=your_stripe_key

# AI Services
REPLICATE_API_KEY=your_replicate_key
OPENAI_API_KEY=your_openai_key
```

## Key Features Implementation

### 1. Skin Analysis Flow
1. User uploads 3 selfies via PhotosUI
2. Images uploaded to Firebase Storage
3. FastAPI backend processes images with AI
4. Results returned with conditions and confidence scores
5. Personalized recommendations generated

### 2. AI Chat Integration
1. User messages sent to FastAPI backend
2. GPT-4o processes with user context
3. Responses include skincare advice and tips
4. Conversation history maintained

### 3. Dashboard Insights
1. Progress tracking with visual metrics
2. Weather integration for recommendations
3. Apple Watch data for activity-based advice
4. Routine completion tracking

### 4. Monetization
1. Stripe integration for subscriptions
2. Premium features gating
3. Product recommendations with affiliate links
4. Subscription management in profile

## Development Notes

### Architecture
- **MVVM Pattern** - Clean separation of concerns
- **Environment Objects** - State management across views
- **Async/Await** - Modern concurrency for API calls
- **SwiftUI** - Declarative UI with previews

### Security
- Firebase Authentication for user management
- Secure image upload to Firebase Storage
- API key management via environment variables
- Data privacy compliance (GDPR, CCPA)

### Performance
- Image compression before upload
- Lazy loading for large lists
- Caching for frequently accessed data
- Background processing for AI analysis

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Contact: ankushkamble1999@gmail.com

## Roadmap

### Phase 1 (Current)
- [x] Basic app structure
- [x] Authentication system
- [x] Skin analysis UI
- [x] Chat interface
- [x] Dashboard layout

### Phase 2 (Next)
- [ ] FastAPI backend integration
- [ ] AI image analysis
- [ ] GPT-4o chat implementation
- [ ] Firebase configuration

### Phase 3 (Future)
- [ ] Apple Watch integration
- [ ] Stripe payment processing
- [ ] Advanced analytics
- [ ] Social features

---

**BeautyAI** - Your AI-powered skin health companion ✨ 