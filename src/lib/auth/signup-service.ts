import { supabase } from '../supabase';
import { validateEmail, validatePassword, validateOrganizationCode, validateOrganizationName } from '../../utils/validation';
import { handleAuthError, SignupError } from '../../utils/error-handler';
import type { SignupData, OrganizationSignupData, SignupResponse } from './types';

function generateOrgCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const parts: string[] = [];
  for (let i = 0; i < 4; i++) {
    const part = Array.from(
      { length: 4 }, 
      () => chars[Math.floor(Math.random() * chars.length)]
    ).join('');
    parts.push(part);
  }
  return parts.join('-');
}

export const signupService = {
  async signUpOrganization(data: OrganizationSignupData): Promise<SignupResponse> {
    // Validate input
    const emailError = validateEmail(data.email);
    if (emailError) throw new SignupError(emailError, 'INVALID_EMAIL');

    const passwordError = validatePassword(data.password);
    if (passwordError) throw new SignupError(passwordError, 'INVALID_PASSWORD');

    const orgNameError = validateOrganizationName(data.organizationName);
    if (orgNameError) throw new SignupError(orgNameError, 'INVALID_ORG_NAME');

    try {
      // First sign up the user
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          emailRedirectTo: `${window.location.origin}/verify-email`
        }
      });

      if (signUpError) throw signUpError;
      if (!authData.user) throw new Error('Signup failed');

      // Generate organization code
      const orgCode = generateOrgCode();

      // Create organization
      const { data: org, error: orgError } = await supabase
        .from('organizations')
        .insert({
          name: data.organizationName,
          admin_id: authData.user.id,
          code: orgCode
        })
        .select()
        .single();

      if (orgError) throw orgError;

      return {
        accessToken: authData.session?.access_token || '',
        user: {
          id: authData.user.id,
          email: authData.user.email || '',
          emailVerified: false,
          role: 'admin'
        }
      };
    } catch (error) {
      throw handleAuthError(error);
    }
  },

  async signUpWithOrgCode(data: SignupData): Promise<SignupResponse> {
    // Validate input
    const emailError = validateEmail(data.email);
    if (emailError) throw new SignupError(emailError, 'INVALID_EMAIL');

    const passwordError = validatePassword(data.password);
    if (passwordError) throw new SignupError(passwordError, 'INVALID_PASSWORD');

    if (data.organizationCode) {
      const orgCodeError = validateOrganizationCode(data.organizationCode);
      if (orgCodeError) throw new SignupError(orgCodeError, 'INVALID_ORG_CODE');
    }

    try {
      // First verify organization code if provided
      if (data.organizationCode) {
        const { data: org, error: orgError } = await supabase
          .from('organizations')
          .select('id')
          .eq('code', data.organizationCode)
          .single();

        if (orgError || !org) {
          throw new SignupError('Invalid organization code', 'INVALID_ORG_CODE');
        }
      }

      // Sign up the user
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            organization_code: data.organizationCode
          },
          emailRedirectTo: `${window.location.origin}/verify-email`
        }
      });

      if (signUpError) throw signUpError;
      if (!authData.user) throw new Error('Signup failed');

      return {
        accessToken: authData.session?.access_token || '',
        user: {
          id: authData.user.id,
          email: authData.user.email || '',
          emailVerified: false,
          role: data.organizationCode ? 'nurse' : 'clinician'
        }
      };
    } catch (error) {
      throw handleAuthError(error);
    }
  }
};