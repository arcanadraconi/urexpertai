import fetch from 'node-fetch';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const supabaseUrl = 'https://rctwnzuwtkrwwlkstrew.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjdHduenV3dGtyd3dsa3N0cmV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDg4OTE3NCwiZXhwIjoyMDUwNDY1MTc0fQ.CwbCupUu84phu2ugvmhdAAINUV0KR4D-67Hs1kETuIQ';

async function createExecSQLFunction() {
  console.log('Creating exec_sql function...');
  
  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/run_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': serviceRoleKey,
      'Authorization': `Bearer ${serviceRoleKey}`
    },
    body: JSON.stringify({
      sql: `
        CREATE OR REPLACE FUNCTION exec_sql(query text)
        RETURNS json
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        BEGIN
          EXECUTE query;
          RETURN json_build_object('success', true);
        END;
        $$;
      `
    })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to create exec_sql function: ${error}`);
  }

  console.log('exec_sql function created successfully');
}

async function runSQL() {
  try {
    // Create exec_sql function first
    await createExecSQLFunction();

    // Read setup file
    const setupPath = path.join(process.cwd(), 'supabase', 'setup.sql');
    const sql = fs.readFileSync(setupPath, 'utf8');

    // Split SQL into individual statements
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0);

    console.log(`Found ${statements.length} SQL statements to execute`);

    // Execute each statement separately
    for (const statement of statements) {
      console.log('\nExecuting statement:', statement.substring(0, 100) + '...');
      
      const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': serviceRoleKey,
          'Authorization': `Bearer ${serviceRoleKey}`
        },
        body: JSON.stringify({
          query: statement
        })
      });

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`SQL error: ${error}`);
      }

      const result = await response.json();
      console.log('Statement executed successfully');
    }

    console.log('\nAll SQL statements completed successfully');

  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

runSQL();
