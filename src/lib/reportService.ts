import { supabase } from './supabase';
import type { ManualEntryData, ProcessedReport } from '../types/report.types';
import { patientService } from './patientService';

export const reportService = {
  async processManualEntry(data: ManualEntryData): Promise<ProcessedReport> {
    // First, create or update patient record
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .upsert({
        mrn: data.patientInfo.mrn || `MANUAL-${Date.now()}`,
        full_name: data.patientInfo.name,
        date_of_birth: data.patientInfo.dateOfBirth,
        gender: data.patientInfo.gender,
      })
      .select()
      .single();

    if (patientError) throw patientError;

    // Generate report content from clinical data
    const content = {
      diagnosis: data.clinicalData.assessment || '',
      treatmentPlan: data.clinicalData.plan || '',
      medicalNecessity: this.extractMedicalNecessity(data.clinicalData),
      clinicalFindings: this.formatClinicalFindings(data.clinicalData),
      recommendations: data.clinicalData.plan || '',
    };

    // Create report
    const { data: report, error: reportError } = await supabase
      .from('reports')
      .insert({
        patient_id: patient.id,
        provider_id: (await supabase.auth.getUser()).data.user?.id,
        content,
        status: 'draft',
      })
      .select()
      .single();

    if (reportError) throw reportError;

    return report;
  },

  private extractMedicalNecessity(clinicalData: ManualEntryData['clinicalData']): string {
    const relevantSections = [
      clinicalData.chiefComplaint,
      clinicalData.presentIllness,
      clinicalData.assessment,
    ].filter(Boolean);

    return relevantSections.join('\n\n');
  },

  private formatClinicalFindings(clinicalData: ManualEntryData['clinicalData']): string {
    const sections = [
      ['Chief Complaint', clinicalData.chiefComplaint],
      ['Present Illness', clinicalData.presentIllness],
      ['Physical Examination', clinicalData.physicalExam],
      ['Past Medical History', clinicalData.pastHistory],
      ['Medications', clinicalData.medications],
      ['Allergies', clinicalData.allergies],
    ];

    return sections
      .filter(([_, content]) => content)
      .map(([title, content]) => `${title}:\n${content}`)
      .join('\n\n');
  },

  async getReport(id: string): Promise<ProcessedReport> {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  },

  async updateReport(id: string, updates: Partial<ProcessedReport>): Promise<ProcessedReport> {
    const { data, error } = await supabase
      .from('reports')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },
};