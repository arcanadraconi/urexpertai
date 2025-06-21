# URExpert Database Migration Instructions

## Quick Start

The migration files have been prepared and are ready to be executed. Follow these steps:

### Step 1: Open Supabase SQL Editor
1. Go to your [Supabase Dashboard](https://vlewkbrdstfvzixlfhyc.supabase.co)
2. Navigate to the SQL Editor: https://vlewkbrdstfvzixlfhyc.supabase.co/project/vlewkbrdstfvzixlfhyc/sql

### Step 2: Execute Migrations

#### Option A: Single Consolidated File (Recommended)
1. Open `consolidated_migration.sql` in your text editor
2. Copy the entire contents
3. Paste into the SQL Editor
4. Click "Run" to execute all migrations at once

#### Option B: Chunked Execution (If Option A fails)
If the consolidated file is too large, use the chunked files:
1. Start with `migration_chunk_1.sql`
2. Copy, paste, and run each chunk sequentially
3. Continue through all 13 chunks

### Step 3: Apply Auth Triggers
1. Open `auth_triggers.sql`
2. Copy the entire contents
3. Paste into the SQL Editor
4. Click "Run" to create the auth triggers

### Step 4: Verify Migration
1. Open `verify_database.sql`
2. Copy and run in SQL Editor
3. Check that all tables, functions, and policies were created

## Files Created

- `consolidated_migration.sql` - All migrations in one file (except auth triggers)
- `migration_chunk_1.sql` through `migration_chunk_13.sql` - Smaller chunks
- `auth_triggers.sql` - Auth.users triggers (requires superuser)
- `verify_database.sql` - Verification queries

## What Was Migrated

### Core Tables
- users (user profiles)
- organizations (multi-tenant organizations)
- branches (organization branches)
- patients (patient records)
- reports (medical reports)
- audit_logs (activity tracking)
- password_reset_tokens
- email_verifications

### Functions
- generate_org_code() - Generates unique organization codes
- handle_new_user() - Handles user creation workflow

### Features
- Row Level Security (RLS) on all tables
- Multi-tenant organization support
- Email verification system
- Audit logging
- Storage bucket for avatars

## Troubleshooting

### Common Issues

1. **"relation already exists" errors**
   - This means some tables were already created
   - You can safely ignore these errors

2. **"permission denied for schema auth" errors**
   - The auth.users trigger requires superuser permissions
   - Use the `auth_triggers.sql` file in the Dashboard

3. **Large file errors**
   - Use the chunked files instead of the consolidated file
   - Run chunks one at a time

### Manual Verification

After migration, run these queries to verify:

```sql
-- Check if all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check row counts
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'organizations', COUNT(*) FROM organizations
UNION ALL
SELECT 'reports', COUNT(*) FROM reports;
```

## Next Steps

1. Test user signup flow
2. Verify organization creation works
3. Test the AI medical review generation
4. Check that all RLS policies are working

## Support

If you encounter issues:
1. Check the Supabase logs in the Dashboard
2. Verify all environment variables are set correctly
3. Ensure the service key has proper permissions