import { supabase } from '../supabase';

export const verificationService = {
  async verifyEmail(token: string) {
    try {
      const { error } = await supabase.auth.verifyOtp({
        token_hash: token,
        type: 'signup'
      });

      if (error) throw error;
      return { verified: true };
    } catch (error) {
      console.error('Email verification failed:', error);
      throw error;
    }
  },

  async resendVerification(email: string) {
    try {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email,
        options: {
          emailRedirectTo: `${window.location.origin}/verify-email`
        }
      });

      if (error) throw error;
      return { message: 'Verification email sent successfully' };
    } catch (error) {
      console.error('Failed to resend verification:', error);
      throw error;
    }
  }
};