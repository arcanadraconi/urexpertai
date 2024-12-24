import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../../lib/supabase';
import { validateEmail, validatePassword } from '../../../utils/validation';

interface FormData {
  email: string;
  password: string;
  confirmPassword: string;
  organizationCode: string;
}

export function OrganizationCodeSignup() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState<FormData>({
    email: '',
    password: '',
    confirmPassword: '',
    organizationCode: ''
  });
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const formatOrgCode = (code: string) => {
    // Remove all non-alphanumeric characters and convert to uppercase
    const cleaned = code.replace(/[^A-Z0-9]/gi, '').toUpperCase();
    
    // Split into groups of 4
    const groups = cleaned.match(/.{1,4}/g) || [];
    
    // Join with hyphens, limiting to 4 groups
    return groups.slice(0, 4).join('-');
  };

  const handleOrgCodeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const formatted = formatOrgCode(e.target.value);
    setFormData(prev => ({ ...formData, organizationCode: formatted }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      // Validate inputs
      const emailError = validateEmail(formData.email);
      if (emailError) throw new Error(emailError);

      const passwordError = validatePassword(formData.password);
      if (passwordError) throw new Error(passwordError);

      if (formData.password !== formData.confirmPassword) {
        throw new Error('Passwords do not match');
      }

      if (!acceptedTerms) {
        throw new Error('Please accept the terms and conditions');
      }

      // Verify organization code exists
      const { data: orgData, error: orgError } = await supabase
        .from('organizations')
        .select('id')
        .eq('code', formData.organizationCode)
        .single();

      if (orgError || !orgData) {
        throw new Error('Invalid organization code');
      }

      // Sign up the user
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            organization_code: formData.organizationCode
          },
          emailRedirectTo: `${window.location.origin}/verify-email`
        }
      });

      if (signUpError) throw signUpError;
      if (!authData.user) throw new Error('Signup failed');

      navigate('/verify-email', { state: { email: formData.email } });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create account');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="mt-8 space-y-4">
      {error && (
        <div className="p-3 text-sm rounded-md bg-destructive/10 text-destructive">
          {error}
        </div>
      )}

      <div className="space-y-4">
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          placeholder="Enter your email"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          autoComplete="email"
        />

        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={(e) => setFormData({ ...formData, password: e.target.value })}
          placeholder="Create password"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          minLength={8}
        />

        <input
          type="password"
          name="confirmPassword"
          value={formData.confirmPassword}
          onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
          placeholder="Confirm password"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
        />

        <input
          type="text"
          name="organizationCode"
          value={formData.organizationCode}
          onChange={handleOrgCodeChange}
          placeholder="Enter organization code (XXXX-XXXX-XXXX-XXXX)"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          maxLength={19}
        />

        <label className="flex items-start space-x-2">
          <input
            type="checkbox"
            checked={acceptedTerms}
            onChange={(e) => setAcceptedTerms(e.target.checked)}
            className="mt-1 h-4 w-4 rounded border-input text-primary focus:ring-primary"
            required
          />
          <span className="text-sm text-muted-foreground">
            By signing up, you agree to our{' '}
            <a href="/terms" className="text-primary hover:underline dark:text-[#8BBFC1]">
              Terms of Service
            </a>
            {' '}and{' '}
            <a href="/privacy" className="text-primary hover:underline dark:text-[#8BBFC1]">
              Privacy Policy
            </a>
          </span>
        </label>
      </div>

      <button
        type="submit"
        className="w-full h-12 text-base gradient-primary hover:opacity-90 transition-opacity text-white rounded-md font-medium"
        disabled={loading}
      >
        {loading ? 'Creating Account...' : 'Create Account'}
      </button>

      <div className="space-y-2 text-center text-sm">
        <p>
          Already have an account?{' '}
          <button
            onClick={() => navigate('/')}
            className="text-primary hover:underline dark:text-[#8BBFC1]"
            type="button"
          >
            Sign in
          </button>
        </p>
      </div>
    </form>
  );
}