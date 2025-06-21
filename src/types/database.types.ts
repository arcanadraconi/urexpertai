export interface Profile {
  id: string;
  email: string;
  role: 'admin' | 'reviewer' | 'provider' | 'nurse';
  organization_id?: string;
  branch_id?: string;
  created_at: string;
  updated_at: string;
  organization?: Organization;
  branch?: Branch;
}

export interface Organization {
  id: string;
  name: string;
  admin_id: string;
  code: string;
  created_at: string;
  updated_at: string;
}

export interface Branch {
  id: string;
  organization_id: string;
  name: string;
  location?: string;
  created_at: string;
  updated_at: string;
}

export interface VerificationResult {
  verified: boolean;
  role: Profile['role'];
  isOrganizationAdmin: boolean;
  organizationCode: string | null;
  organizationName: string | null;
  branchName: string | null;
}
