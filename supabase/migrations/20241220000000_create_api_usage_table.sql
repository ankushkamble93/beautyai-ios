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

-- Create function to get user's current usage stats
CREATE OR REPLACE FUNCTION get_user_api_usage_stats(user_uuid UUID)
RETURNS TABLE (
    total_requests_today INTEGER,
    total_tokens_today INTEGER,
    total_cost_today DECIMAL(10,6),
    requests_this_minute INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(COUNT(*), 0)::INTEGER as total_requests_today,
        COALESCE(SUM(tokens_used), 0)::INTEGER as total_tokens_today,
        COALESCE(SUM(cost_usd), 0)::DECIMAL(10,6) as total_cost_today,
        COALESCE(COUNT(*) FILTER (WHERE timestamp >= NOW() - INTERVAL '1 minute'), 0)::INTEGER as requests_this_minute
    FROM api_usage 
    WHERE user_id = user_uuid 
    AND timestamp >= DATE_TRUNC('day', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
