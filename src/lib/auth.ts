import { supabase } from './supabase';
import type { 
  AuthResponse, 
  UserSignupFormData, 
  OrganizationSignupFormData, 
  OrganizationCodeSignupFormData 
} from '../types/auth.types';

export const auth = {
  async signUpUser(data: UserSignupFormData): Promise<AuthResponse> {
    console.log('Signing up user:', data.email);
    
    const { data: authData, error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          // No extra metadata needed - trigger will set role to 'admin'
        },
        emailRedirectTo: `${window.location.origin}/verify-email`
      }
    });

    if (error) {
      console.error('Signup error:', error);
      throw error;
    }

    console.log('Signup successful:', authData);

    return {
      access_token: authData.session?.access_token || '',
      user: {
        id: authData.user?.id || '',
        email: authData.user?.email || '',
        email_verified: authData.user?.email_confirmed_at != null
      }
    };
  },

  async signUpWithOrganizationCode(data: OrganizationCodeSignupFormData): Promise<AuthResponse> {
    console.log('Signing up with organization code:', data.organizationCode);
    
    // Verify the code exists first
    const { data: orgData, error: orgError } = await supabase
      .from('organizations')
      .select('id')
      .eq('code', data.organizationCode)
      .single();

    if (orgError || !orgData) {
      throw new Error('Invalid organization code');
    }
    
    const { data: authData, error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          organization_code: data.organizationCode
        },
        emailRedirectTo: `${window.location.origin}/verify-email`
      }
    });

    if (error) {
      console.error('Signup error:', error);
      throw error;
    }

    console.log('Signup successful:', authData);

    return {
      access_token: authData.session?.access_token || '',
      user: {
        id: authData.user?.id || '',
        email: authData.user?.email || '',
        email_verified: authData.user?.email_confirmed_at != null
      }
    };
  },

  async signUpOrganization(data: OrganizationSignupFormData): Promise<AuthResponse> {
    const organizationName = data.organizationName.trim();
    console.log('Signing up organization:', organizationName);
    
    // Validate organization name
    if (organizationName.length < 3) {
      throw new Error('Organization name must be at least 3 characters');
    }
    
    const { data: authData, error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          organizationName: organizationName
        },
        emailRedirectTo: `${window.location.origin}/verify-email`
      }
    });

    if (error) {
      console.error('Signup error:', error);
      throw error;
    }

    console.log('Signup successful:', authData);

    return {
      access_token: authData.session?.access_token || '',
      user: {
        id: authData.user?.id || '',
        email: authData.user?.email || '',
        email_verified: authData.user?.email_confirmed_at != null
      }
    };
  },

  async signIn(email: string, password: string): Promise<AuthResponse> {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;

    return {
      access_token: data.session?.access_token || '',
      user: {
        id: data.user?.id || '',
        email: data.user?.email || '',
        email_verified: data.user?.email_confirmed_at != null
      }
    };
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    localStorage.removeItem('token');
  }
};
