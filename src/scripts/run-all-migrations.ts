const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

// Load environment variables from .env file
const envPath = path.join(__dirname, '../../.env');
const envContent = fs.readFileSync(envPath, 'utf-8');
const env = dotenv.parse(envContent);

const supabase = createClient(
  env.VITE_SUPABASE_URL,
  env.VITE_SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

async function createMigrationsTable() {
  // Create a table to track applied migrations if it doesn't exist
  const { error } = await supabase.rpc('exec_sql', {
    query: `
      CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        applied_at TIMESTAMPTZ DEFAULT NOW()
      );
    `
  });

  if (error) {
    console.error('Error creating migrations table:', error);
    throw error;
  }
}

interface MigrationRow {
  name: string;
}

async function getAppliedMigrations(): Promise<string[]> {
  const { data, error } = await supabase
    .from('_migrations')
    .select('name')
    .order('applied_at', { ascending: true });

  if (error) {
    console.error('Error getting applied migrations:', error);
    throw error;
  }

  return data.map((row: MigrationRow) => row.name);
}

async function markMigrationAsApplied(name: string) {
  const { error } = await supabase
    .from('_migrations')
    .insert([{ name }]);

  if (error) {
    console.error('Error marking migration as applied:', error);
    throw error;
  }
}

async function runAllMigrations() {
  try {
    console.log('Creating migrations tracking table...');
    await createMigrationsTable();

    console.log('Getting list of applied migrations...');
    const appliedMigrations = await getAppliedMigrations();

    // Get all migration files
const migrationsDir = path.join(process.cwd(), 'supabase', 'migrations');
const migrationFiles = fs.readdirSync(migrationsDir)
      .filter((file: string) => file.endsWith('.sql'))
      .sort(); // Ensures migrations run in order

    console.log(`Found ${migrationFiles.length} migration files`);

    // Run each migration that hasn't been applied yet
    for (const file of migrationFiles as string[]) {
      if (appliedMigrations.includes(file)) {
        console.log(`Migration ${file} already applied, skipping...`);
        continue;
      }

      console.log(`\nApplying migration ${file}...`);
      const migrationPath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(migrationPath, 'utf8');

      // Split into individual statements
      const statements = sql
        .split(';')
        .map((s: string) => s.trim())
        .filter((s: string) => s.length > 0);

      console.log(`Found ${statements.length} SQL statements`);

      // Execute each statement
      for (const statement of statements) {
        console.log('\nExecuting statement:', statement.substring(0, 100) + '...');
        
        const { error } = await supabase.rpc('exec_sql', {
          query: statement
        });

        if (error) {
          console.error('Error executing statement:', error);
          throw error;
        }
        
        console.log('Statement executed successfully');
      }

      // Mark migration as applied
      await markMigrationAsApplied(file);
      console.log(`Migration ${file} completed and marked as applied`);
    }

    console.log('\nAll migrations completed successfully');

  } catch (error) {
    console.error('Migration error:', error);
    process.exit(1);
  }
}

// Run migrations
runAllMigrations();
