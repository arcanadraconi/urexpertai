import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://vlewkbrdstfvzixlfhyc.supabase.co';
const serviceRoleKey = process.env.VITE_SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsZXdrYnJkc3RmdnppeGxmaHljIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTQzMzg2MywiZXhwIjoyMDY1MDA5ODYzfQ.1vEc1a9uTOSBdYOFcZ-zr7P4uuTsloRV_0WxRbPnSl0';

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function verifySchemaFix() {
  console.log('🔍 Verifying schema fix...');
  
  const expectedTables = [
    'access_keys',
    'subscribers', 
    'user_metrics',
    'user_sessions',
    'user_settings',
    'review_activities',
    'user_profiles',
    'organization_branches',
    'organizations',
    'reports'
  ];

  let successCount = 0;
  let totalChecks = 0;

  console.log('\n📋 Checking table existence:');
  
  for (const tableName of expectedTables) {
    totalChecks++;
    try {
      const { error } = await supabase
        .from(tableName)
        .select('count', { count: 'exact', head: true });
      
      if (error) {
        console.log(`❌ ${tableName}: ${error.message}`);
      } else {
        console.log(`✅ ${tableName}: exists`);
        successCount++;
      }
    } catch (err) {
      console.log(`❌ ${tableName}: failed to check`);
    }
  }

  console.log('\n🔍 Checking specific schema changes:');
  
  // Check if organizations has unique_code column
  totalChecks++;
  try {
    const { error } = await supabase
      .from('organizations')
      .select('unique_code')
      .limit(1);
    
    if (error) {
      console.log('❌ organizations.unique_code: not found');
    } else {
      console.log('✅ organizations.unique_code: exists');
      successCount++;
    }
  } catch (err) {
    console.log('❌ organizations.unique_code: failed to check');
  }

  // Check if reports has new columns
  totalChecks++;
  try {
    const { error } = await supabase
      .from('reports')
      .select('title, report_type, metadata, file_url, user_id')
      .limit(1);
    
    if (error) {
      console.log('❌ reports new columns: not found');
    } else {
      console.log('✅ reports new columns: exists');
      successCount++;
    }
  } catch (err) {
    console.log('❌ reports new columns: failed to check');
  }

  // Check if organization_branches has branch_code
  totalChecks++;
  try {
    const { error } = await supabase
      .from('organization_branches')
      .select('branch_code')
      .limit(1);
    
    if (error) {
      console.log('❌ organization_branches.branch_code: not found');
    } else {
      console.log('✅ organization_branches.branch_code: exists');
      successCount++;
    }
  } catch (err) {
    console.log('❌ organization_branches.branch_code: failed to check');
  }

  console.log('\n📊 Verification Results:');
  console.log(`✅ Passed: ${successCount}/${totalChecks} checks`);
  
  if (successCount === totalChecks) {
    console.log('🎉 Schema fix completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Update TypeScript types to match new schema');
    console.log('2. Update application code to use new table names');
    console.log('3. Test authentication and signup flows');
  } else {
    console.log('⚠️  Some checks failed. Please review the migration and try again.');
  }
}

verifySchemaFix().catch(console.error);