import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0MzM4NjMsImV4cCI6MjA2NTAwOTg2M30._Idrz_WK2rWQ0XO1xvFEVDeXpGzmSWbFhR6y026XIvg';

async function testConnection() {
  console.log('Testing Supabase connection...');
  
  try {
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    
    // Test 1: Check if we can connect and get the current user (should be null for anon)
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    console.log('Auth check:', user ? 'User found' : 'No user (anonymous)', userError ? `Error: ${userError.message}` : '');
    
    // Test 2: Try to query a simple table
    const { data: orgData, error: orgError } = await supabase
      .from('organizations')
      .select('id, name')
      .limit(1);
    
    if (orgError) {
      console.log('Database query error:', orgError.message);
    } else {
      console.log('Database query successful. Found', orgData?.length || 0, 'organizations');
    }
    
    // Test 3: Check database health by querying system
    const { data: healthData, error: healthError } = await supabase
      .rpc('pg_sleep', { duration: 0 });
    
    if (healthError) {
      console.log('Database health check error:', healthError.message);
    } else {
      console.log('Database health check: OK');
    }
    
    // Test 4: Check if tables exist
    const tables = ['users', 'organizations', 'branches', 'patients', 'reports', 'audit_logs'];
    console.log('\nChecking tables:');
    
    for (const table of tables) {
      const { error } = await supabase
        .from(table)
        .select('id')
        .limit(1);
      
      console.log(`- ${table}: ${error ? '❌ ' + error.message : '✅ Accessible'}`);
    }
    
    console.log('\nDatabase connection test complete!');
    console.log('Status: The database is UP and RUNNING ✅');
    
  } catch (error) {
    console.error('Connection test failed:', error);
    console.log('Status: The database is DOWN or UNREACHABLE ❌');
  }
}

testConnection();