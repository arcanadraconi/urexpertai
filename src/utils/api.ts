import { supabase } from '../lib/supabase';
import type { 
  SignupFormData, 
  OrganizationSignupFormData, 
  AuthResponse, 
  TokenVerificationResponse,
  UserResponse 
} from '../types/auth.types';

export const ApiService = {
  async signup(data: SignupFormData | OrganizationSignupFormData): Promise<AuthResponse> {
    const { data: authData, error } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          ...(('organizationName' in data) && { organizationName: data.organizationName }),
          ...(('organizationCodeId' in data) && { organizationCodeId: data.organizationCodeId })
        }
      }
    });

    if (error) throw error;

    return {
      access_token: authData.session?.access_token || '',
      user: {
        id: authData.user?.id || '',
        email: authData.user?.email || '',
        email_verified: authData.user?.email_confirmed_at != null
      }
    };
  },

  async login(email: string, password: string): Promise<AuthResponse> {
    const { data: authData, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;

    return {
      access_token: authData.session?.access_token || '',
      user: {
        id: authData.user?.id || '',
        email: authData.user?.email || '',
        email_verified: authData.user?.email_confirmed_at != null
      }
    };
  },

  async logout(): Promise<void> {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    localStorage.removeItem('token');
  }
};

export default ApiService;