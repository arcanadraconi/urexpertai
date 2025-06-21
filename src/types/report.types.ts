export interface ManualEntryData {
  patientInfo: {
    mrn?: string;
    name: string;
    dateOfBirth: string;
    gender: string;
  };
  clinicalData: {
    chiefComplaint?: string;
    presentIllness?: string;
    physicalExam?: string;
    pastHistory?: string;
    medications?: string;
    allergies?: string;
    assessment?: string;
    plan?: string;
  };
}

export interface ProcessedReport {
  id: string;
  patient_id: string;
  provider_id: string;
  content: {
    diagnosis: string;
    treatmentPlan: string;
    medicalNecessity: string;
    clinicalFindings: string;
    recommendations: string;
    fullReview?: string; // Complete AI-generated review text
  };
  status: 'draft' | 'submitted' | 'reviewed' | 'approved' | 'rejected';
  report_type?: 'manual' | 'ai_generated';
  created_at: string;
  updated_at: string;
}