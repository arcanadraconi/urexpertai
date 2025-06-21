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

async function runMigration() {
  try {
    // Read migration file
    const migrationPath = join(process.cwd(), 'supabase', 'migrations', '0033_quick_spark.sql');
    const sql = readFileSync(migrationPath, 'utf8');

    // Split into individual statements
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0);

    console.log(`Found ${statements.length} SQL statements`);

    // Execute each statement
    for (const statement of statements) {
      console.log('\nExecuting statement:', statement.substring(0, 100) + '...');
      
      const { data, error } = await supabase.rpc('exec_sql', {
        query: statement
      });

      if (error) {
        console.error('Error executing statement:', error);
      } else {
        console.log('Statement executed successfully');
      }
    }

    console.log('\nMigration completed');

  } catch (error) {
    console.error('Error:', error);
  }
}

runMigration();
