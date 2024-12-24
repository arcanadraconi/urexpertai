import { supabase } from './supabase';
import type { MappedPatient } from '../types/fhir.types';

export const patientService = {
  async getPatients(page = 1, limit = 20) {
    const start = (page - 1) * limit;
    const end = start + limit - 1;

    const { data, error, count } = await supabase
      .from('patients')
      .select('*', { count: 'exact' })
      .range(start, end)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return { data, count };
  },

  async getPatientByMRN(mrn: string) {
    const { data, error } = await supabase
      .from('patients')
      .select('*')
      .eq('mrn', mrn)
      .single();

    if (error) throw error;
    return data;
  },

  async searchPatients(query: string) {
    const { data, error } = await supabase
      .from('patients')
      .select('*')
      .or(`full_name.ilike.%${query}%,mrn.ilike.%${query}%`)
      .limit(10);

    if (error) throw error;
    return data;
  }
};