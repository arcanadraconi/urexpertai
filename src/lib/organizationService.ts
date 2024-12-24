import { supabase } from './supabase';

export const organizationService = {
  async getOrganizations() {
    const { data, error } = await supabase
      .from('organizations')
      .select('*');
    
    if (error) throw error;
    return data;
  },

  async getOrganization(id: string) {
    const { data, error } = await supabase
      .from('organizations')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    return data;
  }
};