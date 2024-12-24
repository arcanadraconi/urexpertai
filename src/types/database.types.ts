export interface User {
  id: string;
  email: string;
  created_at: string;
  role: 'admin' | 'reviewer' | 'provider';
}

export interface Report {
  id: string;
  patient_id: string;
  provider_id: string;
  status: 'draft' | 'submitted' | 'reviewed' | 'approved' | 'rejected';
  created_at: string;
  updated_at: string;
  content: ReportContent;
}

export interface ReportContent {
  diagnosis: string;
  treatment_plan: string;
  medical_necessity: string;
  clinical_findings: string;
  recommendations: string;
}