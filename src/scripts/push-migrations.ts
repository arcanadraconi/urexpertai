import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

const SUPABASE_URL = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

async function pushMigrations() {
  console.log('🚀 Pushing migrations to Supabase...\n');

  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  
  // Critical migrations that set up the base schema
  const criticalMigrations = [
    '0001_square_meadow.sql',    // Base tables
    '0002_falling_truth.sql',     // Organizations
    '0007_wispy_cake.sql',        // generate_org_code function
    '0033_quick_spark.sql',       // Major refactor
  ];

  // First, let's create a single consolidated migration
  let consolidatedSQL = `-- URExpert Database Schema
-- Generated on ${new Date().toISOString()}

`;

  console.log('📦 Building consolidated migration...\n');

  // Add critical migrations
  for (const file of criticalMigrations) {
    const filePath = path.join(migrationsDir, file);
    if (fs.existsSync(filePath)) {
      const sql = fs.readFileSync(filePath, 'utf8');
      consolidatedSQL += `\n-- ========== ${file} ==========\n${sql}\n`;
      console.log(`   ✅ Added ${file}`);
    }
  }

  // Add other migrations, skipping problematic ones
  const allFiles = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  const skipFiles = [
    '0034_soft_moon.sql',
    '0067_withered_field.sql',
    '0070_precious_delta.sql',
    ...criticalMigrations
  ];

  console.log('\n📦 Adding remaining migrations...\n');

  for (const file of allFiles) {
    if (skipFiles.includes(file)) continue;
    
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // Skip auth.users triggers
    if (sql.includes('CREATE TRIGGER') && sql.includes('auth.users')) {
      console.log(`   ⏭️  Skipping ${file} (auth.users trigger)`);
      continue;
    }
    
    consolidatedSQL += `\n-- ========== ${file} ==========\n${sql}\n`;
    console.log(`   ✅ Added ${file}`);
  }

  // Write consolidated file
  const outputPath = path.join(process.cwd(), 'consolidated_migration.sql');
  fs.writeFileSync(outputPath, consolidatedSQL);
  
  console.log(`\n✅ Consolidated migration saved to: ${outputPath}`);
  console.log(`   Total size: ${(consolidatedSQL.length / 1024).toFixed(2)} KB`);

  // Now let's try to execute via the management API
  console.log('\n🔄 Attempting to execute migrations...\n');

  try {
    // Create connection string
    const connectionString = `postgresql://postgres.${SUPABASE_URL.split('.')[0].split('//')[1]}:[YOUR-PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres`;
    
    console.log('📋 Migration Instructions:\n');
    console.log('Since direct SQL execution requires database credentials, please:');
    console.log('\n1. Go to your Supabase Dashboard');
    console.log(`2. Navigate to: ${SUPABASE_URL}/project/${SUPABASE_URL.split('.')[0].split('//')[1]}/sql`);
    console.log('3. Open the SQL Editor');
    console.log('4. Copy and paste the contents of consolidated_migration.sql');
    console.log('5. Click "Run" to execute all migrations\n');
    
    console.log('Alternatively, you can use the Supabase CLI:');
    console.log('1. Install Supabase CLI: npm install -g supabase');
    console.log('2. Link your project: supabase link --project-ref ' + SUPABASE_URL.split('.')[0].split('//')[1]);
    console.log('3. Run: supabase db push consolidated_migration.sql\n');

    // Let's also create smaller chunks for easier execution
    const chunks = [];
    const statements = consolidatedSQL.split(/;\s*\n/);
    const chunkSize = 20;
    
    for (let i = 0; i < statements.length; i += chunkSize) {
      chunks.push(statements.slice(i, i + chunkSize).join(';\n') + ';');
    }
    
    console.log(`📂 Also created ${chunks.length} smaller chunks for easier execution:`);
    
    chunks.forEach((chunk, index) => {
      const chunkPath = path.join(process.cwd(), `migration_chunk_${index + 1}.sql`);
      fs.writeFileSync(chunkPath, chunk);
      console.log(`   - migration_chunk_${index + 1}.sql`);
    });

  } catch (error) {
    console.error('Error:', error);
  }

  // Create verification script
  const verificationSQL = `
-- Verification Queries
-- Run these after migration to verify everything was created

-- Check tables
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check functions
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- Check if key tables have data
SELECT 'organizations' as table_name, COUNT(*) as row_count FROM organizations
UNION ALL
SELECT 'users' as table_name, COUNT(*) as row_count FROM users
UNION ALL  
SELECT 'reports' as table_name, COUNT(*) as row_count FROM reports;

-- Check RLS policies
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
`;

  fs.writeFileSync(path.join(process.cwd(), 'verify_database.sql'), verificationSQL);
  console.log('\n✅ Created verify_database.sql to check migration results');
}

pushMigrations().catch(console.error);