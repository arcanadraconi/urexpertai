import * as fs from 'fs';
import * as path from 'path';

const SUPABASE_URL = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

async function executeSql(sql: string): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SERVICE_KEY,
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify({ query: sql })
    });

    if (response.ok) {
      return { success: true };
    } else {
      const error = await response.text();
      return { success: false, error };
    }
  } catch (error) {
    return { success: false, error: String(error) };
  }
}

async function runMigrations() {
  console.log('🚀 Starting database migration...\n');
  
  const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
  const migrationFiles = fs.readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  console.log(`📁 Found ${migrationFiles.length} migration files\n`);

  // Skip known problematic migrations
  const skipPatterns = [
    '0034_soft_moon.sql', // Missing file
    '0067_withered_field.sql', // Duplicate number
    '0070_precious_delta.sql', // Duplicate number
  ];

  // Group migrations by type for better organization
  const criticalMigrations = migrationFiles.filter(f => 
    f.includes('_meadow') || f.includes('_truth') || f.includes('_cake') || 
    f.includes('0033_quick_spark') || f.includes('0075_long_shadow')
  );
  
  const regularMigrations = migrationFiles.filter(f => 
    !criticalMigrations.includes(f) && !skipPatterns.some(p => f.includes(p))
  );

  console.log('📋 Migration Plan:');
  console.log(`   - Critical migrations: ${criticalMigrations.length}`);
  console.log(`   - Regular migrations: ${regularMigrations.length}`);
  console.log(`   - Skipped migrations: ${skipPatterns.length}\n`);

  // Apply critical migrations first
  console.log('1️⃣  Applying critical migrations...\n');
  
  for (const file of criticalMigrations) {
    console.log(`   Running ${file}...`);
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf8');
    
    // For critical migrations, we'll create a combined SQL file
    const tempFile = path.join(process.cwd(), `critical_migrations.sql`);
    fs.appendFileSync(tempFile, `\n-- ${file}\n${sql}\n`);
    console.log(`   ✅ Added to critical migrations bundle`);
  }

  console.log('\n2️⃣  Creating migration bundles for regular migrations...\n');

  // Bundle regular migrations in groups of 10
  const bundleSize = 10;
  const bundles: string[][] = [];
  
  for (let i = 0; i < regularMigrations.length; i += bundleSize) {
    bundles.push(regularMigrations.slice(i, i + bundleSize));
  }

  bundles.forEach((bundle, index) => {
    const bundleFile = path.join(process.cwd(), `migration_bundle_${index + 1}.sql`);
    let bundleSql = `-- Migration Bundle ${index + 1}\n`;
    
    bundle.forEach(file => {
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');
      bundleSql += `\n-- ${file}\n${sql}\n`;
    });
    
    fs.writeFileSync(bundleFile, bundleSql);
    console.log(`   ✅ Created bundle ${index + 1} with ${bundle.length} migrations`);
  });

  console.log('\n📝 Migration files have been prepared!');
  console.log('\n🔧 Next Steps:');
  console.log('1. Go to your Supabase Dashboard SQL Editor');
  console.log(`2. Open: ${SUPABASE_URL}/project/vlewkbrdstfvzixlfhyc/sql`);
  console.log('3. Run the following files in order:');
  console.log('   - critical_migrations.sql');
  bundles.forEach((_, index) => {
    console.log(`   - migration_bundle_${index + 1}.sql`);
  });
  console.log('\n💡 Tips:');
  console.log('- If a migration fails, check the error and fix it before continuing');
  console.log('- Some triggers on auth.users may fail - these need superuser permissions');
  console.log('- You can run migrations one by one from the individual files if needed');

  // Create a verification script
  const verifyScript = `
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
`;

  fs.writeFileSync(path.join(process.cwd(), 'verify_migration.sql'), verifyScript);
  console.log('\n✅ Created verify_migration.sql to check the migration results');
}

// Run the migration preparation
runMigrations().catch(console.error);