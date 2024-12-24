export interface Branch {
  id: string;
  name: string;
  location: string;
  organization_id: string;
  admin_id?: string;
  created_at: string;
}

export interface OrganizationUser {
  id: string;
  email: string;
  role: string;
  full_name?: string;
  branch_id?: string;
  created_at: string;
}

export interface AuditLog {
  id: string;
  user_id: string;
  action: string;
  details: Record<string, any>;
  created_at: string;
}