import { supabase } from '../supabase';
import type { Profile, VerificationResult } from '../../types/database.types';

export const verificationService = {
  async verifyEmail(token: string): Promise<VerificationResult> {
    try {
      const { error } = await supabase.auth.verifyOtp({
        token_hash: token,
        type: 'signup'
      });

      if (error) throw error;

      // Get the user's metadata to check if they're an organization admin
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;

      if (!user) throw new Error('User not found');

      // Get user's profile with organization info
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select(`
          id,
          email,
          role,
          organization:organizations (
            id,
            code,
            name
          ),
          branch:branches (
            id,
            name
          )
        `)
        .eq('id', user.id)
        .single();

      if (profileError) throw profileError;

      if (!profile) throw new Error('Profile not found');

      const result: VerificationResult = {
        verified: true,
        role: profile.role,
        isOrganizationAdmin: profile.role === 'admin' && profile.organization != null,
        organizationCode: profile.organization?.code,
        organizationName: profile.organization?.name,
        branchName: profile.branch?.name
      };

      return result;
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
