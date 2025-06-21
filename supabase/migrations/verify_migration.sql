
-- Verification Script
-- Run this after migrations to check if everything was created

SELECT 'Tables' as category, count(*) as count 
FROM information_schema.tables 
WHERE table_schema = 'public';

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT 'Functions' as category, count(*) as count
FROM information_schema.routines
WHERE routine_schema = 'public';

SELECT 'Triggers' as category, count(*) as count
FROM information_schema.triggers
WHERE trigger_schema = 'public';

SELECT 'Policies' as category, count(*) as count
FROM pg_policies
WHERE schemaname = 'public';
