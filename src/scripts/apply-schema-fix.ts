import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join } from 'path';

const supabaseUrl = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function executeSqlFile(filePath: string, fileName: string) {
  try {
    console.log(`\n=== Executing ${fileName} ===`);
    const sql = readFileSync(filePath, 'utf8');

    // Execute the entire migration as one transaction
    const { error } = await supabase.rpc('exec_sql', {
      query: sql
    });

    if (error) {
      console.error(`Error executing ${fileName}:`, error);
      throw error;
    } else {
      console.log(`✅ ${fileName} executed successfully`);
    }
  } catch (error) {
    console.error(`❌ Failed to execute ${fileName}:`, error);
    throw error;
  }
}

async function applySchemaFix() {
  try {
    console.log('🚀 Starting schema fix migration...');

    // Apply migrations in order
    const migrations = [
      '0076_add_missing_tables.sql',
      '0077_fix_existing_tables.sql'
    ];

    for (const migration of migrations) {
      const migrationPath = join(process.cwd(), 'supabase', 'migrations', migration);
      await executeSqlFile(migrationPath, migration);
    }

    console.log('\n🎉 Schema fix completed successfully!');
    
    // Verify tables exist
    console.log('\n🔍 Verifying new tables...');
    const tableNames = [
      'access_keys',
      'subscribers', 
      'user_metrics',
      'user_sessions',
      'user_settings',
      'review_activities',
      'user_profiles',
      'organization_branches'
    ];

    for (const tableName of tableNames) {
      const { error } = await supabase
        .from(tableName)
        .select('count', { count: 'exact', head: true });
      
      if (error) {
        console.error(`❌ Table ${tableName} not found:`, error.message);
      } else {
        console.log(`✅ Table ${tableName} exists`);
      }
    }

  } catch (error) {
    console.error('💥 Schema fix failed:', error);
    process.exit(1);
  }
}

applySchemaFix();