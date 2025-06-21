const fetch = require('node-fetch');
const fs = require('fs');
const path = require('path');

const supabaseUrl = 'https://rctwnzuwtkrwwlkstrew.supabase.co';
const serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjdHduenV3dGtyd3dsa3N0cmV3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDg4OTE3NCwiZXhwIjoyMDUwNDY1MTc0fQ.CwbCupUu84phu2ugvmhdAAINUV0KR4D-67Hs1kETuIQ';

async function runSQL() {
  try {
    // Read migration file
    const setupPath = path.join(process.cwd(), 'supabase', 'setup.sql');
    const sql = fs.readFileSync(setupPath, 'utf8');

    // Execute SQL directly through REST API
    // Split SQL into individual statements
    const statements = sql
      .split(';')
      .map((s: string) => s.trim())
      .filter((s: string) => s.length > 0);

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
  }
}

runSQL();
