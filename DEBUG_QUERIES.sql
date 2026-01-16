-- Run these queries in your Supabase SQL editor to check if logs are being saved

-- 1. Check daily_logs table
SELECT * FROM daily_logs 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. Check mental_logs table
SELECT * FROM mental_logs 
ORDER BY created_at DESC 
LIMIT 10;

-- 3. Check physical_logs table
SELECT * FROM physical_logs 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. Check all logs for a specific user (replace YOUR_USER_ID with actual UUID)
SELECT 
    d.log_date,
    d.mental_mood,
    d.physical_score,
    m.mood as mental_mood_detail,
    m.score as mental_score,
    m.note,
    p.activity_level,
    p.steps,
    p.workout_done
FROM daily_logs d
LEFT JOIN mental_logs m ON d.user_id = m.user_id AND d.log_date = m.log_date
LEFT JOIN physical_logs p ON d.user_id = p.user_id AND d.log_date = p.log_date
WHERE d.user_id = 'YOUR_USER_ID'
ORDER BY d.log_date DESC;

-- 5. Count logs by user
SELECT 
    user_id,
    COUNT(*) as daily_logs_count
FROM daily_logs
GROUP BY user_id;

-- 6. Check most recent logs
SELECT 
    'daily_logs' as table_name,
    COUNT(*) as count,
    MAX(created_at) as latest_entry
FROM daily_logs
UNION ALL
SELECT 
    'mental_logs' as table_name,
    COUNT(*) as count,
    MAX(created_at) as latest_entry
FROM mental_logs
UNION ALL
SELECT 
    'physical_logs' as table_name,
    COUNT(*) as count,
    MAX(created_at) as latest_entry
FROM physical_logs;
