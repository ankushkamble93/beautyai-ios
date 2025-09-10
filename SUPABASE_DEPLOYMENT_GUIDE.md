# Supabase Backend Integration Guide

This guide explains how to set up the Supabase backend for the Nura iOS app, including the OpenAI proxy Edge Function and usage tracking.

## Overview

The app uses Supabase as a secure backend proxy for OpenAI API calls, providing:
- **Security**: API keys are never exposed client-side
- **Rate Limiting**: Per-user API usage tracking and limits
- **Authentication**: JWT-based user authentication
- **Monitoring**: Detailed usage analytics and cost tracking

## Prerequisites

- Supabase account and project
- OpenAI API key
- Supabase CLI (optional, for local development)

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your project URL and API keys

## Step 2: Set Up Edge Function

### Create the Function:
1. Go to **Edge Functions** in your Supabase dashboard
2. Click **Create a new function**
3. Name it: `openai-proxy`
4. Copy the code from `supabase/functions/openai-proxy/index.ts`

### Add Environment Variables:
1. Go to **Settings** → **Edge Functions**
2. Add these environment variables:

```
OPENAI_API_KEY=YOUR_OPENAI_API_KEY_HERE
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY_HERE
SBASE_JWT_SECRET=YOUR_JWT_SECRET_HERE
```

### To get your service role key:
1. Go to **Settings** → **API**
2. Copy the **service_role** key (NOT the anon key)

### To get your JWT secret:
1. Go to **Settings** → **Auth** → **JWT Settings**
2. Copy the **JWT Secret** value

## Step 3: Deploy the Edge Function

```bash
# Deploy the function
supabase functions deploy openai-proxy

# Verify deployment
supabase functions list
```

## Step 4: Create Database Table

### Option A: Via Supabase Dashboard
1. Go to **SQL Editor**
2. Run this SQL:

```sql
-- Create API usage tracking table
CREATE TABLE IF NOT EXISTS api_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    model TEXT NOT NULL,
    tokens_used INTEGER NOT NULL DEFAULT 0,
    cost_usd DECIMAL(10,6) NOT NULL DEFAULT 0,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    request_type TEXT NOT NULL DEFAULT 'chat_completion',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_api_usage_user_id ON api_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_timestamp ON api_usage(timestamp);
CREATE INDEX IF NOT EXISTS idx_api_usage_user_timestamp ON api_usage(user_id, timestamp);

-- Enable Row Level Security
ALTER TABLE api_usage ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own usage" ON api_usage
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own usage" ON api_usage
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Option B: Via Migration File
```bash
supabase db push
```

## Step 5: Test the Function

### Test URL:
```
https://your-project.supabase.co/functions/v1/openai-proxy
```

### Test with curl:
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/openai-proxy \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [
      {
        "role": "user",
        "content": "Hello, how are you?"
      }
    ]
  }'
```

## Step 6: Update iOS App

The iOS app has already been updated to use the Supabase proxy. The changes include:

1. ✅ `APIConfig.swift` - Updated to use Supabase proxy endpoints
2. ✅ `SupabaseProxyManager.swift` - New manager for proxy calls
3. ✅ `ChatGPTServiceManager.swift` - Updated to use proxy
4. ✅ `UsageAnalyticsManager.swift` - New manager for usage tracking

## Step 7: Verify Everything Works

1. **Build and run** your iOS app
2. **Test API calls** - they should now go through Supabase
3. **Check usage tracking** - verify data appears in the `api_usage` table
4. **Monitor logs** - check Edge Function logs for any errors

## Security Notes

- ✅ **API keys are never exposed** to the client
- ✅ **All requests are authenticated** via JWT tokens
- ✅ **Rate limiting** is enforced per user
- ✅ **Usage tracking** provides transparency and control

## Troubleshooting

### Common Issues:

1. **401 Unauthorized**: Check JWT token and JWT secret
2. **500 Internal Error**: Check Edge Function logs and environment variables
3. **Rate Limit Exceeded**: Check user tier and usage limits

### Debug Steps:

1. Check Edge Function logs in Supabase dashboard
2. Verify environment variables are set correctly
3. Test with a simple curl request first
4. Check iOS app logs for detailed error messages

## Next Steps

Once everything is working:
1. Set up monitoring and alerts
2. Configure usage limits per user tier
3. Implement cost optimization strategies
4. Add more sophisticated rate limiting rules

---

**Implementation Status**: ✅ Complete
**Last Updated**: December 20, 2024
**Version**: 2.0.0