import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { create, verify } from "https://deno.land/x/djwt@v2.9.1/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface OpenAIRequest {
  model: string
  messages: Array<{
    role: string
    content: string | Array<{
      type: string
      text?: string
      image_url?: {
        url: string
      }
    }>
  }>
  maxTokens?: number
  temperature?: number
}

interface UsageRecord {
  user_id: string
  model: string
  tokens_used: number
  cost_usd: number
  timestamp: string
  request_type: string
}

interface JWTPayload {
  sub: string
  email: string
  aud: string
  exp: number
  iat: number
}

      serve(async (req) => {
        console.log('🚀 Function called with method:', req.method)
        console.log('🚀 Request URL:', req.url)
        console.log('🚀 Request headers:', Object.fromEntries(req.headers.entries()))
        
        // Handle CORS preflight requests
        if (req.method === 'OPTIONS') {
          console.log('🚀 Handling CORS preflight')
          return new Response('ok', { headers: corsHeaders })
        }

        try {
          console.log('🚀 Processing request...')
          
          // Get the authorization header
          const authHeader = req.headers.get('authorization')
          console.log('🚀 Auth header:', authHeader ? 'Present' : 'Missing')
          
          if (!authHeader) {
            console.log('🚀 No auth header, returning 401')
            return new Response(
              JSON.stringify({ error: 'Authorization header required' }),
              { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
          }

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Verify the JWT token manually
    const token = authHeader.replace('Bearer ', '')
    let userId: string
    let userEmail: string
    
    try {
      // Get JWT secret from environment
      const jwtSecret = Deno.env.get('SBASE_JWT_SECRET')
      if (!jwtSecret) {
        console.error('SBASE_JWT_SECRET not configured')
        return new Response(
          JSON.stringify({ error: 'Server configuration error' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      console.log('JWT Secret length:', jwtSecret.length)
      console.log('Token length:', token.length)
      console.log('Token starts with:', token.substring(0, 20))
      
      // Verify JWT token with Deno-compatible library
      const key = await crypto.subtle.importKey(
        "raw",
        new TextEncoder().encode(jwtSecret),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["verify"]
      )
      
      const decoded = await verify(token, key) as JWTPayload
      
      console.log('🔍 FULL JWT PAYLOAD:', JSON.stringify(decoded, null, 2))
      console.log('JWT decoded successfully:', { userId: decoded.sub, email: decoded.email, aud: decoded.aud })
      
      // Check if token is expired
      const now = Math.floor(Date.now() / 1000)
      if (decoded.exp < now) {
        console.log('Token expired. Exp:', decoded.exp, 'Now:', now)
        return new Response(
          JSON.stringify({ error: 'Token expired' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      // Check if token is for authenticated users
      console.log('🔍 Checking audience. Expected: "authenticated", Got:', decoded.aud)
      
      // More flexible audience check - some tokens might not have aud field
      if (decoded.aud && decoded.aud !== 'authenticated') {
        console.log('Invalid audience:', decoded.aud)
        return new Response(
          JSON.stringify({ error: 'Invalid token audience' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      console.log('✅ Audience check passed')
      
      userId = decoded.sub
      userEmail = decoded.email
      
    } catch (jwtError) {
      console.error('JWT verification failed:', jwtError)
      console.error('JWT error details:', jwtError.message)
      return new Response(
        JSON.stringify({ error: 'Invalid token format', details: jwtError.message }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check rate limiting
    const rateLimitResult = await checkRateLimit(supabase, userId)
    if (!rateLimitResult.allowed) {
      return new Response(
        JSON.stringify({ 
          error: 'Rate limit exceeded', 
          retryAfter: rateLimitResult.retryAfter 
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

              console.log('🚀 About to parse request body...')
          
          // Parse the request body
          const requestBody: OpenAIRequest = await req.json()
          console.log('🚀 Request body parsed:', JSON.stringify(requestBody, null, 2))
          
          // Validate request
          if (!requestBody.model || !requestBody.messages) {
            console.log('🚀 Invalid request format - missing model or messages')
            return new Response(
              JSON.stringify({ error: 'Invalid request format' }),
              { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
          }

    // Get OpenAI API key from environment
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      return new Response(
        JSON.stringify({ error: 'OpenAI API key not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Make request to OpenAI
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    })

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.text()
      return new Response(
        JSON.stringify({ error: 'OpenAI API error', details: errorData }),
        { status: openaiResponse.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const openaiData = await openaiResponse.json()

    // Track usage
    await trackUsage(supabase, {
      user_id: userId,
      model: requestBody.model,
      tokens_used: openaiData.usage?.total_tokens || 0,
      cost_usd: calculateCost(requestBody.model, openaiData.usage?.total_tokens || 0),
      timestamp: new Date().toISOString(),
      request_type: 'chat_completion'
    })

    // Return the OpenAI response
    return new Response(
      JSON.stringify(openaiData),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in OpenAI proxy:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

async function checkRateLimit(supabase: any, userId: string): Promise<{ allowed: boolean; retryAfter?: number }> {
  const now = new Date()
  const oneMinuteAgo = new Date(now.getTime() - 60 * 1000)
  
  // Get user's tier for rate limiting
  const { data: profile } = await supabase
    .from('profiles')
    .select('premium_tier')
    .eq('id', userId)
    .single()

  const tier = profile?.premium_tier || 'free'
  const maxRequestsPerMinute = getMaxRequestsForTier(tier)

  // Count requests in the last minute
  const { count } = await supabase
    .from('api_usage')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('timestamp', oneMinuteAgo.toISOString())

  if (count && count >= maxRequestsPerMinute) {
    // Calculate retry after time
    const oldestRequest = await supabase
      .from('api_usage')
      .select('timestamp')
      .eq('user_id', userId)
      .gte('timestamp', oneMinuteAgo.toISOString())
      .order('timestamp', { ascending: true })
      .limit(1)
      .single()

    if (oldestRequest.data) {
      const retryAfter = Math.ceil((60 - (now.getTime() - new Date(oldestRequest.data.timestamp).getTime()) / 1000))
      return { allowed: false, retryAfter }
    }
  }

  return { allowed: true }
}

function getMaxRequestsForTier(tier: string): number {
  switch (tier) {
    case 'pro_unlimited':
      return 100
    case 'pro':
      return 60
    case 'free':
    default:
      return 20
  }
}

async function trackUsage(supabase: any, usage: UsageRecord) {
  try {
    await supabase
      .from('api_usage')
      .insert(usage)
  } catch (error) {
    console.error('Failed to track usage:', error)
  }
}

function calculateCost(model: string, tokens: number): number {
  // OpenAI pricing (as of 2024, adjust as needed)
  const pricing: { [key: string]: { input: number; output: number } } = {
    'gpt-4o': { input: 0.0025, output: 0.01 },
    'gpt-4o-mini': { input: 0.00015, output: 0.0006 },
    'gpt-3.5-turbo': { input: 0.0005, output: 0.0015 }
  }

  const modelPricing = pricing[model] || pricing['gpt-4o-mini']
  // Assume 80% input, 20% output tokens for cost calculation
  const inputTokens = Math.floor(tokens * 0.8)
  const outputTokens = tokens - inputTokens
  
  return (inputTokens * modelPricing.input + outputTokens * modelPricing.output) / 1000
}
