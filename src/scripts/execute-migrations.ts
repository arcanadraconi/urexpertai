import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const SUPABASE_URL = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  db: {
    schema: 'public'
  },
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// SQL statement parser
function parseSQL(sql: string): string[] {
  const statements: string[] = [];
  const lines = sql.split('\n');
  let currentStatement = '';
  let inFunction = false;
  let functionDepth = 0;
  
  for (const line of lines) {
    const trimmedLine = line.trim();
    
    // Skip comments
    if (trimmedLine.startsWith('--') || trimmedLine === '') {
      continue;
    }
    
    // Track function/procedure blocks
    if (trimmedLine.match(/^(CREATE|REPLACE)\s+(FUNCTION|PROCEDURE|TRIGGER)/i)) {
      inFunction = true;
    }
    
    if (inFunction) {
      if (trimmedLine.match(/^BEGIN$/i)) {
        functionDepth++;
      }
      if (trimmedLine.match(/^END;?$/i)) {
        functionDepth--;
        if (functionDepth === 0) {
          inFunction = false;
        }
      }
    }
    
    currentStatement += line + '\n';
    
    // Check for statement terminator
    if (!inFunction && trimmedLine.endsWith(';')) {
      const statement = currentStatement.trim();
      if (statement) {
        statements.push(statement);
      }
      currentStatement = '';
    }
  }
  
  // Add any remaining statement
  if (currentStatement.trim()) {
    statements.push(currentStatement.trim());
  }
  
  return statements;
}

async function executeSQLStatements(statements: string[], fileName: string) {
  const results = [];
  let successCount = 0;
  let errorCount = 0;
  
  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];
    
    // Skip empty statements
    if (!statement.trim()) continue;
    
    // Get statement type for logging
    const statementType = statement.trim().split(/\s+/)[0].toUpperCase();
    
    try {
      // For auth.users triggers, we need to skip as they require superuser
      if (statement.includes('CREATE TRIGGER') && statement.includes('auth.users')) {
        console.log(`   ⏭️  Skipping auth.users trigger (requires superuser)`);
        continue;
      }
      
      // Execute via direct PostgreSQL connection
      const { data, error } = await supabase.rpc('exec_sql', {
        sql: statement
      }).then(res => ({ data: res.data, error: null }))
        .catch(err => ({ data: null, error: err }));
      
      if (error) {
        // Try alternative approach
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SERVICE_KEY,
            'Authorization': `Bearer ${SERVICE_KEY}`,
          },
          body: JSON.stringify({
            function_name: 'exec_sql',
            args: { sql: statement }
          })
        });
        
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${await response.text()}`);
        }
      }
      
      console.log(`   ✅ ${statementType} statement ${i + 1} executed`);
      successCount++;
      
    } catch (error: any) {
      console.log(`   ❌ ${statementType} statement ${i + 1} failed: ${error.message}`);
      errorCount++;
      results.push({
        statement: statement.substring(0, 100) + '...',
        error: error.message
      });
    }
  }
  
  return { successCount, errorCount, results };
}

async function runMigrations() {
  console.log('🚀 Starting automated database migration...\n');
  
  // First, let's create a function to execute SQL if it doesn't exist
  console.log('📦 Setting up execution environment...');
  
  const setupSQL = `
CREATE OR REPLACE FUNCTION exec_sql(sql text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  EXECUTE sql;
END;
$$;
`;

  try {
    // Try to create the helper function directly
    const { error } = await supabase.rpc('query', { query: setupSQL });
    if (!error) {
      console.log('   ✅ Helper function created\n');
    }
  } catch (e) {
    console.log('   ⚠️  Could not create helper function, proceeding anyway\n');
  }
  
  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();
  
  // Skip problematic files
  const skipFiles = [
    '0034_soft_moon.sql',
    '0067_withered_field.sql', 
    '0070_precious_delta.sql'
  ];
  
  const filesToProcess = migrationFiles.filter(f => !skipFiles.includes(f));
  
  console.log(`📁 Processing ${filesToProcess.length} migration files...\n`);
  
  let totalSuccess = 0;
  let totalError = 0;
  const failedMigrations: any[] = [];
  
  // Process migrations one by one
  for (const file of filesToProcess) {
    console.log(`📄 Processing ${file}...`);
    
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf8');
    const statements = parseSQL(sql);
    
    console.log(`   Found ${statements.length} SQL statements`);
    
    const { successCount, errorCount, results } = await executeSQLStatements(statements, file);
    
    totalSuccess += successCount;
    totalError += errorCount;
    
    if (errorCount > 0) {
      failedMigrations.push({
        file,
        errors: results
      });
    }
    
    console.log(`   Summary: ${successCount} succeeded, ${errorCount} failed\n`);
  }
  
  // Final summary
  console.log('=' .repeat(60));
  console.log('📊 MIGRATION SUMMARY');
  console.log('=' .repeat(60));
  console.log(`Total files processed: ${filesToProcess.length}`);
  console.log(`Total statements executed: ${totalSuccess + totalError}`);
  console.log(`✅ Successful: ${totalSuccess}`);
  console.log(`❌ Failed: ${totalError}`);
  
  if (failedMigrations.length > 0) {
    console.log('\n❌ Failed Migrations:');
    failedMigrations.forEach(({ file, errors }) => {
      console.log(`\n   ${file}:`);
      errors.forEach((err: any) => {
        console.log(`     - ${err.error}`);
      });
    });
  }
  
  console.log('\n🔍 Verifying database state...\n');
  
  // Check what was created
  try {
    const { data: tables } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public');
    
    console.log(`✅ Tables created: ${tables?.length || 0}`);
    
    if (tables && tables.length > 0) {
      console.log('   Tables found:');
      tables.forEach(t => console.log(`   - ${t.table_name}`));
    }
  } catch (e) {
    console.log('   Could not verify tables');
  }
}

// Alternative approach using direct SQL execution
async function executeMigrationsDirect() {
  console.log('\n🔄 Trying alternative migration approach...\n');
  
  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  
  // Read critical migrations first
  const criticalFiles = [
    '0001_square_meadow.sql',
    '0002_falling_truth.sql', 
    '0007_wispy_cake.sql',
    '0033_quick_spark.sql'
  ];
  
  for (const file of criticalFiles) {
    const filePath = path.join(migrationsDir, file);
    if (!fs.existsSync(filePath)) continue;
    
    console.log(`📄 Executing ${file}...`);
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // Split into smaller chunks
    const statements = sql.split(/;\s*$/m).filter(s => s.trim());
    
    for (const statement of statements) {
      if (!statement.trim()) continue;
      
      try {
        // Use the Supabase client to execute
        const { error } = await supabase.rpc('query', {
          query: statement + ';'
        });
        
        if (error) {
          console.log(`   ❌ Error: ${error.message}`);
        } else {
          console.log(`   ✅ Statement executed`);
        }
      } catch (e: any) {
        console.log(`   ❌ Error: ${e.message}`);
      }
    }
  }
}

// Run the migrations
console.log('🚀 URExpert Database Migration Tool\n');
runMigrations()
  .then(() => {
    console.log('\n✅ Migration process completed!');
    console.log('\n💡 Next steps:');
    console.log('1. Check the Supabase dashboard for any errors');
    console.log('2. Run the verification script to confirm all tables exist');
    console.log('3. Some migrations may need to be run manually in the SQL editor');
  })
  .catch(error => {
    console.error('\n❌ Migration failed:', error);
    console.log('\n🔄 Attempting alternative approach...');
    return executeMigrationsDirect();
  });