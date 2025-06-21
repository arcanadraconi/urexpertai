import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { auth } from '../../../lib/auth';
import { validateEmail, validatePassword, validateOrganizationName } from '../../../utils/validation';

interface FormData {
  email: string;
  password: string;
  confirmPassword: string;
  organizationName: string;
}

export function OrganizationSignup() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState<FormData>({
    email: '',
    password: '',
    confirmPassword: '',
    organizationName: ''
  });
  const [acceptedTerms, setAcceptedTerms] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      // Validate all inputs first
      const validationErrors = [
        validateEmail(formData.email),
        validatePassword(formData.password),
        validateOrganizationName(formData.organizationName),
      ].filter(Boolean);

      if (validationErrors.length > 0) {
        throw new Error(validationErrors[0]);
      }

      if (formData.password !== formData.confirmPassword) {
        throw new Error('Passwords do not match');
      }

      if (!acceptedTerms) {
        throw new Error('Please accept the terms and conditions');
      }

      // Create organization account
      await auth.signUpOrganization({
        email: formData.email,
        password: formData.password,
        confirmPassword: formData.confirmPassword,
        organizationName: formData.organizationName.trim()
      });

      navigate('/verify-email', { 
        state: { 
          email: formData.email,
          message: 'Please check your email to verify your account. Once verified, you will receive your organization code.'
        } 
      });
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
          type="text"
          name="organizationName"
          value={formData.organizationName}
          onChange={(e) => setFormData({ ...formData, organizationName: e.target.value })}
          placeholder="Enter organization name"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
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
        className="w-full h-12 text-base gradient-primary hover:opacity-90 transition-opacity text-white rounded-md font-medium disabled:opacity-50"
        disabled={loading}
      >
        {loading ? 'Creating Account...' : 'Create Account'}
      </button>

      <p className="text-center text-sm">
        Already have an account?{' '}
        <button
          onClick={() => navigate('/')}
          className="text-primary hover:underline dark:text-[#8BBFC1]"
          type="button"
        >
          Sign in
        </button>
      </p>
    </form>
  );
}
