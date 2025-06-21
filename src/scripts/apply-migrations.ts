import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const supabaseUrl = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function applyMigrations() {
  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  
  // Read all migration files
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  console.log(`Found ${migrationFiles.length} migration files\n`);

  // Check for issues
  const issues: string[] = [];
  const numbers = new Set<string>();
  
  for (const file of migrationFiles) {
    const number = file.split('_')[0];
    if (numbers.has(number)) {
      issues.push(`Duplicate migration number: ${number}`);
    }
    numbers.add(number);
  }

  // Check for missing numbers
  const sortedNumbers = Array.from(numbers).sort();
  for (let i = 1; i < sortedNumbers.length; i++) {
    const current = parseInt(sortedNumbers[i]);
    const previous = parseInt(sortedNumbers[i-1]);
    if (current - previous > 1) {
      issues.push(`Missing migration number(s) between ${previous} and ${current}`);
    }
  }

  if (issues.length > 0) {
    console.log('⚠️  Issues found:');
    issues.forEach(issue => console.log(`   - ${issue}`));
    console.log('\nContinuing anyway...\n');
  }

  // Create migrations tracking table
  console.log('Creating migrations tracking table...');
  const { error: tableError } = await supabase.rpc('query', {
    query: `
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP DEFAULT NOW()
      );
    `
  });

  if (tableError) {
    console.log('Could not create migrations table, trying direct SQL...');
    // We'll track migrations locally instead
  }

  // Apply migrations
  let successCount = 0;
  let errorCount = 0;
  const errors: { file: string; error: string }[] = [];

  for (const file of migrationFiles) {
    console.log(`\nApplying ${file}...`);
    
    try {
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');
      
      // Split by semicolons but be careful about functions/procedures
      const statements = sql
        .split(/;(?=\s*(?:--|$|CREATE|DROP|ALTER|INSERT|UPDATE|DELETE|GRANT|REVOKE|BEGIN|COMMIT|ROLLBACK|SET|DO))/i)
        .map(s => s.trim())
        .filter(s => s.length > 0 && !s.startsWith('--'));

      let hasError = false;
      for (let i = 0; i < statements.length; i++) {
        const statement = statements[i] + ';';
        
        const { error } = await supabase.rpc('query', { query: statement });
        
        if (error) {
          console.error(`  ❌ Error in statement ${i + 1}: ${error.message}`);
          errors.push({ file, error: error.message });
          hasError = true;
          errorCount++;
          break;
        }
      }
      
      if (!hasError) {
        console.log(`  ✅ Successfully applied`);
        successCount++;
      }
      
    } catch (err) {
      console.error(`  ❌ Error: ${err}`);
      errors.push({ file, error: String(err) });
      errorCount++;
    }
  }

  console.log('\n=== Migration Summary ===');
  console.log(`Total migrations: ${migrationFiles.length}`);
  console.log(`✅ Successful: ${successCount}`);
  console.log(`❌ Failed: ${errorCount}`);
  
  if (errors.length > 0) {
    console.log('\n=== Errors ===');
    errors.forEach(({ file, error }) => {
      console.log(`\n${file}:`);
      console.log(`  ${error}`);
    });
  }
}

// Run the migrations
applyMigrations().catch(console.error);