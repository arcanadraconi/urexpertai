import { supabase } from '../supabase';
import type { AuthResponse } from './types';

export const authService = {
  async signIn(email: string, password: string): Promise<AuthResponse> {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw error;

    return {
      accessToken: data.session?.access_token || '',
      user: {
        id: data.user?.id || '',
        email: data.user?.email || '',
        emailVerified: data.user?.email_confirmed_at != null
      }
    };
  },

  async signUp(email: string, password: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/verify-email`
      }
    });

    if (error) throw error;
    return data;
  },

  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  }
};