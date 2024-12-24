import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../../lib/supabase';

interface Props {
  onHasOrgCode: () => void;
}

interface FormData {
  email: string;
  password: string;
  confirmPassword: string;
}

export function UserSignup({ onHasOrgCode }: Props) {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState<FormData>({
    email: '',
    password: '',
    confirmPassword: ''
  });
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!acceptedTerms) {
      setError('Please accept the terms and conditions');
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Sign up the user
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          emailRedirectTo: `${window.location.origin}/verify-email`
        }
      });

      if (signUpError) throw signUpError;
      if (!authData.user) throw new Error('Signup failed');

      // Set default role as clinician for individual users
      const { error: profileError } = await supabase
        .from('profiles')
        .update({ role: 'clinician' })
        .eq('id', authData.user.id);

      if (profileError) throw profileError;

      navigate('/verify-email', { state: { email: formData.email } });
    } catch (err) {
      console.error('Signup error:', err);
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

        <div className="space-y-4">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              onChange={() => onHasOrgCode()}
              className="rounded border-input h-4 w-4 text-primary focus:ring-primary"
            />
            <span className="text-sm">I have an organization code</span>
          </label>
        </div>

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

        <p>
          Want to register your organization?{' '}
          <button
            onClick={() => navigate('/signup/organization')}
            className="text-primary hover:underline dark:text-[#8BBFC1]"
            type="button"
          >
            Click here
          </button>
        </p>
      </div>
    </form>
  );
}