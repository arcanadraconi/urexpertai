import { supabase } from './supabase';
import type { ManualEntryData, ProcessedReport } from '../types/report.types';

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

  extractMedicalNecessity(clinicalData: ManualEntryData['clinicalData']): string {
    const relevantSections = [
      clinicalData.chiefComplaint,
      clinicalData.presentIllness,
      clinicalData.assessment,
    ].filter(Boolean);

    return relevantSections.join('\n\n');
  },

  formatClinicalFindings(clinicalData: ManualEntryData['clinicalData']): string {
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

  async saveAIGeneratedReview(patientData: string, reviewText: string): Promise<any> {
    try {
      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');

      // Extract patient info from the raw data input
      const patientInfo = this.parsePatientData(patientData);
      
      // Get user's organization from auth metadata or profile
      let organizationId = null;
      try {
        const { data: profile } = await supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .single();
        organizationId = profile?.organization_id;
      } catch (error) {
        // If profile lookup fails, continue without organization_id
        console.log('Could not fetch organization_id, continuing without it');
      }

      // Structure the metadata with extracted patient info and content sections
      const metadata = {
        patient_info: patientInfo,
        original_input: patientData.substring(0, 1000), // Store first 1000 chars of input
        content_sections: {
          diagnosis: this.extractSection(reviewText, ['diagnosis', 'assessment']),
          treatmentPlan: this.extractSection(reviewText, ['plan', 'treatment', 'recommendation']),
          medicalNecessity: this.extractSection(reviewText, ['necessity', 'justification']),
          clinicalFindings: this.extractSection(reviewText, ['findings', 'examination', 'clinical']),
          recommendations: this.extractSection(reviewText, ['recommendation', 'plan', 'next steps']),
        }
      };

      // Create report
      const { data: report, error: reportError } = await supabase
        .from('reports')
        .insert({
          user_id: user.id,
          organization_id: organizationId,
          title: `AI Medical Review - ${patientInfo.name || 'Unknown Patient'} - ${new Date().toLocaleDateString()}`,
          report_type: 'ai_generated',
          content: reviewText, // Store full review as text
          metadata,
          status: 'draft',
        })
        .select()
        .single();

      if (reportError) throw reportError;
      return report;
    } catch (error) {
      console.error('Error saving AI-generated review:', error);
      throw error;
    }
  },

  parsePatientData(rawData: string): {
    mrn?: string;
    name?: string;
    dateOfBirth?: string;
    gender?: string;
  } {
    const data = rawData.toLowerCase();
    
    // Extract MRN
    const mrnMatch = data.match(/(?:mrn|medical record number|patient id)[:\s]*([a-zA-Z0-9-]+)/i);
    const mrn = mrnMatch?.[1];

    // Extract name
    const nameMatch = data.match(/(?:name|patient)[:\s]*([a-zA-Z\s,]+)/i);
    const name = nameMatch?.[1]?.trim().replace(/[,:].*/, '');

    // Extract DOB
    const dobMatch = data.match(/(?:dob|date of birth|born)[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/i);
    const dateOfBirth = dobMatch?.[1];

    // Extract gender
    const genderMatch = data.match(/(?:gender|sex)[:\s]*(male|female|m|f)/i);
    const gender = genderMatch?.[1]?.toLowerCase().startsWith('m') ? 'male' :
                   genderMatch?.[1]?.toLowerCase().startsWith('f') ? 'female' : undefined;

    return { mrn, name, dateOfBirth, gender };
  },

  extractSection(text: string, keywords: string[]): string {
    const lines = text.split('\n');
    const relevantLines: string[] = [];
    let isRelevantSection = false;
    
    for (const line of lines) {
      const lowerLine = line.toLowerCase();
      
      // Check if this line starts a relevant section
      if (keywords.some(keyword => lowerLine.includes(keyword))) {
        isRelevantSection = true;
        relevantLines.push(line);
        continue;
      }
      
      // If we're in a relevant section, continue until we hit another section or empty line
      if (isRelevantSection) {
        if (line.trim() === '' || line.match(/^[A-Z][a-z\s]+:/) && !keywords.some(k => lowerLine.includes(k))) {
          isRelevantSection = false;
        } else {
          relevantLines.push(line);
        }
      }
    }
    
    return relevantLines.join('\n').trim() || text.substring(0, 500); // Fallback to first 500 chars
  },
};