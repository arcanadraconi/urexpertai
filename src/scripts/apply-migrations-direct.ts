import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const supabaseUrl = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

interface MigrationResult {
  file: string;
  success: boolean;
  error?: string;
}

async function applyMigrationsSequentially() {
  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  
  // Read and sort migration files
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  console.log(`Found ${migrationFiles.length} migration files\n`);

  // Check for duplicate numbers
  const numberMap = new Map<string, string[]>();
  migrationFiles.forEach(file => {
    const number = file.split('_')[0];
    if (!numberMap.has(number)) {
      numberMap.set(number, []);
    }
    numberMap.get(number)!.push(file);
  });

  // Report duplicates
  const duplicates = Array.from(numberMap.entries())
    .filter(([_, files]) => files.length > 1);
  
  if (duplicates.length > 0) {
    console.log('⚠️  Warning: Duplicate migration numbers found:');
    duplicates.forEach(([number, files]) => {
      console.log(`   ${number}: ${files.join(', ')}`);
    });
    console.log('');
  }

  // Create a consolidated migration script
  console.log('Creating consolidated migration script...\n');
  
  const consolidatedPath = path.join(process.cwd(), 'temp_migration.sql');
  let consolidatedSql = `-- URExpert Database Migration Script
-- Generated on ${new Date().toISOString()}

-- Create schema migrations table
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMP DEFAULT NOW()
);

`;

  const results: MigrationResult[] = [];
  
  // Process each migration file
  for (const file of migrationFiles) {
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // Skip if already has issues we know about
    if (file === '0034_soft_moon.sql') {
      console.log(`⏭️  Skipping missing file: ${file}`);
      continue;
    }
    
    // Handle duplicates - skip the second one
    const number = file.split('_')[0];
    const filesWithNumber = numberMap.get(number)!;
    if (filesWithNumber.length > 1 && filesWithNumber.indexOf(file) > 0) {
      console.log(`⏭️  Skipping duplicate: ${file}`);
      continue;
    }
    
    consolidatedSql += `
-- ============================================
-- Migration: ${file}
-- ============================================

${sql}

-- Record migration
INSERT INTO schema_migrations (version) 
VALUES ('${file}') 
ON CONFLICT (version) DO NOTHING;

`;
  }

  // Write consolidated file
  fs.writeFileSync(consolidatedPath, consolidatedSql);
  console.log(`✅ Consolidated migration script created: ${consolidatedPath}`);
  console.log(`   Total size: ${(consolidatedSql.length / 1024).toFixed(2)} KB\n`);

  // Now let's create individual migration files for better error handling
  console.log('Applying migrations individually...\n');
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  
  let successCount = 0;
  let errorCount = 0;
  
  for (const file of migrationFiles) {
    // Skip duplicates and missing files
    const number = file.split('_')[0];
    const filesWithNumber = numberMap.get(number)!;
    if (filesWithNumber.length > 1 && filesWithNumber.indexOf(file) > 0) {
      continue;
    }
    
    console.log(`Applying ${file}...`);
    
    const filePath = path.join(migrationsDir, file);
    if (!fs.existsSync(filePath)) {
      console.log(`  ⏭️  File not found, skipping`);
      continue;
    }
    
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // Create temporary file for this migration
    const tempFile = path.join(process.cwd(), `temp_${file}`);
    fs.writeFileSync(tempFile, sql);
    
    try {
      // Use psql directly if available, otherwise fallback to API
      // For now, let's parse and execute statement by statement
      const statements = parseSQL(sql);
      let hasError = false;
      
      for (const statement of statements) {
        if (!statement.trim()) continue;
        
        try {
          // Special handling for certain statements
          if (statement.includes('CREATE TRIGGER') && statement.includes('auth.users')) {
            console.log(`  ⚠️  Skipping auth.users trigger (requires superuser)`);
            continue;
          }
          
          const { error } = await supabase.rpc('query', { 
            query: statement 
          }).catch(err => ({ error: err }));
          
          if (error) {
            console.log(`  ❌ Error: ${error.message || error}`);
            hasError = true;
            errorCount++;
            results.push({ file, success: false, error: error.message || String(error) });
            break;
          }
        } catch (err) {
          console.log(`  ❌ Error: ${err}`);
          hasError = true;
          errorCount++;
          results.push({ file, success: false, error: String(err) });
          break;
        }
      }
      
      if (!hasError) {
        console.log(`  ✅ Successfully applied`);
        successCount++;
        results.push({ file, success: true });
      }
      
    } finally {
      // Clean up temp file
      if (fs.existsSync(tempFile)) {
        fs.unlinkSync(tempFile);
      }
    }
  }
  
  // Summary
  console.log('\n=== Migration Summary ===');
  console.log(`Total migrations processed: ${successCount + errorCount}`);
  console.log(`✅ Successful: ${successCount}`);
  console.log(`❌ Failed: ${errorCount}`);
  
  if (errorCount > 0) {
    console.log('\n=== Failed Migrations ===');
    results
      .filter(r => !r.success)
      .forEach(r => {
        console.log(`\n${r.file}:`);
        console.log(`  ${r.error}`);
      });
  }
  
  // Clean up consolidated file
  if (fs.existsSync(consolidatedPath)) {
    fs.unlinkSync(consolidatedPath);
  }
  
  console.log('\n💡 Tip: For migrations that failed due to permissions (like auth.users triggers),');
  console.log('    you may need to apply them through the Supabase dashboard SQL editor.');
}

function parseSQL(sql: string): string[] {
  // This is a simplified SQL parser that handles most common cases
  const statements: string[] = [];
  let current = '';
  let inString = false;
  let stringChar = '';
  let inDollarQuote = false;
  let dollarTag = '';
  
  for (let i = 0; i < sql.length; i++) {
    const char = sql[i];
    const nextChar = sql[i + 1];
    
    // Handle dollar quotes (PostgreSQL specific)
    if (!inString && char === '$' && !inDollarQuote) {
      const match = sql.slice(i).match(/^(\$[^$]*\$)/);
      if (match) {
        inDollarQuote = true;
        dollarTag = match[1];
        current += match[1];
        i += match[1].length - 1;
        continue;
      }
    }
    
    if (inDollarQuote && sql.slice(i).startsWith(dollarTag)) {
      inDollarQuote = false;
      current += dollarTag;
      i += dollarTag.length - 1;
      continue;
    }
    
    // Handle regular strings
    if (!inDollarQuote) {
      if (!inString && (char === "'" || char === '"')) {
        inString = true;
        stringChar = char;
      } else if (inString && char === stringChar && sql[i - 1] !== '\\') {
        inString = false;
      }
    }
    
    current += char;
    
    // Check for statement end
    if (!inString && !inDollarQuote && char === ';') {
      statements.push(current.trim());
      current = '';
    }
  }
  
  if (current.trim()) {
    statements.push(current.trim());
  }
  
  return statements;
}

// Run the migration
applyMigrationsSequentially().catch(console.error);