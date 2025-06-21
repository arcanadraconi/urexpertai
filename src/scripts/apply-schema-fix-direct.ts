import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { join } from 'path';

const supabaseUrl = 'https://rctwnzuwtkrwwlkstrew.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjdHduenV3dGtyd3dsa3N0cmV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDg4OTE3NCwiZXhwIjoyMDUwNDY1MTc0fQ.CwbCupUu84phu2ugvmhdAAINUV0KR4D-67Hs1kETuIQ';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function executeStatements(statements: string[], fileName: string) {
  console.log(`\n=== Executing ${fileName} (${statements.length} statements) ===`);
  
  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];
    if (!statement.trim()) continue;
    
    try {
      console.log(`Executing statement ${i + 1}/${statements.length}...`);
      
      // Use direct SQL query instead of RPC
      const { error } = await supabase
        .from('_temp_migration')
        .select('*')
        .limit(0);
      
      // If that fails, try a simple query to test connection
      if (error) {
        const { error: testError } = await supabase
          .from('organizations')
          .select('id')
          .limit(1);
        
        if (testError) {
          console.error('Connection test failed:', testError);
          throw testError;
        }
        console.log('Connection verified');
      }
      
      // Since we can't execute arbitrary SQL directly, let's output the SQL
      console.log('SQL Statement:', statement.substring(0, 200) + '...');
      
    } catch (error) {
      console.error(`Error in statement ${i + 1}:`, error);
      throw error;
    }
  }
}

async function applySchemaFix() {
  try {
    console.log('🚀 Starting schema fix migration...');
    console.log('⚠️  Note: Due to Supabase limitations, manual SQL execution may be required');

    // Read and output the migration files for manual execution
    const migrations = [
      '0076_add_missing_tables.sql',
      '0077_fix_existing_tables.sql'
    ];

    console.log('\n📝 MIGRATION SQL TO EXECUTE MANUALLY IN SUPABASE SQL EDITOR:');
    console.log('='.repeat(80));

    for (const migration of migrations) {
      const migrationPath = join(process.cwd(), 'supabase', 'migrations', migration);
      const sql = readFileSync(migrationPath, 'utf8');
      
      console.log(`\n-- ========== ${migration} ==========`);
      console.log(sql);
      console.log(`-- ========== END ${migration} ==========\n`);
    }

    console.log('\n🔧 INSTRUCTIONS:');
    console.log('1. Copy the SQL above');
    console.log('2. Go to https://rctwnzuwtkrwwlkstrew.supabase.co/project/rctwnzuwtkrwwlkstrew/sql');
    console.log('3. Paste and execute each migration in order');
    console.log('4. Verify the tables were created successfully');

    // Test connection
    const { error } = await supabase
      .from('organizations')
      .select('id')
      .limit(1);
    
    if (error) {
      console.error('❌ Connection test failed:', error);
    } else {
      console.log('✅ Supabase connection verified');
    }

  } catch (error) {
    console.error('💥 Schema fix preparation failed:', error);
  }
}

applySchemaFix();