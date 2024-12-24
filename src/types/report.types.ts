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
  };
  status: 'draft' | 'submitted' | 'reviewed' | 'approved' | 'rejected';
  created_at: string;
  updated_at: string;
}