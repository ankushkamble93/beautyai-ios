# 🔑 OpenAI API Setup Guide for Nura iOS App

This guide will walk you through setting up the OpenAI API key and testing the ChatGPT Vision integration.

## 📋 Prerequisites

- OpenAI account with API access
- Valid payment method (for API usage costs)
- macOS with Swift installed

## 🚀 Step-by-Step Setup

### 1. Get Your OpenAI API Key

1. **Visit OpenAI Platform**: Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. **Sign In**: Use your OpenAI account credentials
3. **Create New Key**: Click "Create new secret key"
4. **Name Your Key**: Give it a descriptive name (e.g., "Nura iOS App")
5. **Copy the Key**: The key starts with `sk-` (e.g., `sk-abc123...`)
6. **Store Securely**: Keep this key safe - you won't be able to see it again

### 2. Update Configuration Files

#### Option A: Update APIConfig.swift (Recommended for Development)

```swift
// In beautyai-ios/Nura/Config/APIConfig.swift
static let openAIAPIKey = "sk-your-actual-api-key-here"
```

#### Option B: Use Environment Variables (Recommended for Production)

```bash
# Add to your shell profile (.zshrc, .bash_profile, etc.)
export OPENAI_API_KEY="sk-your-actual-api-key-here"
```

Then update `APIConfig.swift`:
```swift
static let openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_OPENAI_API_KEY"
```

### 3. Test the API Integration

#### Basic Test (No API Key Required)
```bash
cd /Users/ankush_kamble/beautyai-ios
swift test_chatgpt_api.swift
```

#### Comprehensive Test (Requires API Key)
1. **Update the test script**:
   ```swift
   // In test_image_analysis.swift
   static let openAIAPIKey = "sk-your-actual-api-key-here"
   ```

2. **Run the comprehensive test**:
   ```bash
   swift test_image_analysis.swift
   ```

## 🧪 Test Results Interpretation

### ✅ Success Indicators
- **HTTP Status 200**: API is working correctly
- **Valid JSON Response**: API is parsing requests properly
- **Image Analysis**: Vision capabilities are functional

### ❌ Common Error Codes
- **401 Unauthorized**: Invalid or missing API key
- **429 Rate Limited**: Too many requests (60/minute limit)
- **400 Bad Request**: Invalid request format
- **500+ Server Error**: OpenAI service issues

## 💰 Cost Management

### Pricing (as of 2024)
- **GPT-3.5 Vision**: $0.0025 per image
- **GPT-4 Vision**: $0.01 per image
- **Rate Limit**: 60 requests per minute

### Cost Optimization Tips
1. **Use GPT-3.5 for Free Users**: Cheaper option for basic analysis
2. **Use GPT-4 for Pro Users**: Higher quality for premium features
3. **Implement Caching**: Store results for 24 hours to reduce API calls
4. **Monitor Usage**: Check OpenAI dashboard regularly

## 🔒 Security Best Practices

### ✅ Do's
- Store API keys in environment variables
- Use different keys for development/production
- Rotate keys periodically
- Monitor API usage for anomalies

### ❌ Don'ts
- Commit API keys to version control
- Share API keys publicly
- Use the same key across multiple projects
- Ignore rate limiting warnings

## 🚨 Troubleshooting

### API Key Issues
```bash
# Check if key is properly set
echo $OPENAI_API_KEY

# Verify key format (should start with sk-)
echo $OPENAI_API_KEY | head -c 3
```

### Network Issues
```bash
# Test basic connectivity
curl -I https://api.openai.com/v1/models

# Test with your API key
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/models
```

### Swift Compilation Issues
```bash
# Check Swift version
swift --version

# Clean and rebuild
xcodebuild clean
xcodebuild build
```

## 📱 Integration Testing

### 1. Test in Xcode Simulator
1. Open your project in Xcode
2. Set a breakpoint in `ChatGPTServiceManager.analyzeSkinImages`
3. Run the app and trigger image analysis
4. Check the debug console for API responses

### 2. Test with Real Images
1. Use the Photos app in simulator
2. Select test images (front, left, right selfies)
3. Verify the analysis flow works end-to-end
4. Check that results are properly cached

## 🔄 Next Steps

After successful API setup:

1. **Phase 1b**: Update Analysis Results Display
2. **Phase 2**: Implement Routine Generation System
3. **Phase 3**: Add ChatGPT Chat Integration
4. **Phase 4**: Implement Tier-Based Features

## 📞 Support

### OpenAI Support
- [OpenAI Help Center](https://help.openai.com/)
- [OpenAI Community](https://community.openai.com/)
- [API Status Page](https://status.openai.com/)

### Nura App Support
- Check the app's error handling
- Review the debug console
- Verify network connectivity
- Test with different image types

---

**⚠️ Important**: Never share your API key publicly. If you accidentally expose it, immediately regenerate it in the OpenAI dashboard. 