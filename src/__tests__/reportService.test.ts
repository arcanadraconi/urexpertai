import { describe, it, expect, vi } from 'vitest';
import { reportService } from '../lib/reportService';
import { supabase } from '../lib/supabase';

vi.mock('../lib/supabase', () => ({
  supabase: {
    from: vi.fn(() => ({
      insert: vi.fn().mockReturnThis(),
      update: vi.fn().mockReturnThis(),
      select: vi.fn().mockReturnThis(),
      single: vi.fn().mockResolvedValue({
        data: {
          id: '123',
          patient_id: '456',
          provider_id: '789',
          content: {
            diagnosis: 'Test diagnosis',
            treatmentPlan: 'Test plan',
            medicalNecessity: 'Test necessity',
            clinicalFindings: 'Test findings',
            recommendations: 'Test recommendations'
          },
          status: 'draft'
        },
        error: null
      })
    }))
  }
}));

describe('reportService', () => {
  it('should process manual entry data', async () => {
    const testData = {
      patientInfo: {
        name: 'John Doe',
        dateOfBirth: '1990-01-01',
        gender: 'male'
      },
      clinicalData: {
        assessment: 'Test assessment',
        plan: 'Test plan'
      }
    };

    const result = await reportService.processManualEntry(testData);

    expect(result).toMatchObject({
      id: '123',
      patient_id: '456',
      status: 'draft'
    });
  });
});