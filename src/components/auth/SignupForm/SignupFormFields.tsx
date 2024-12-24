import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import type { SignupFormData, OrganizationSignupFormData } from '../../../types/auth.types';
import { validateSignupForm } from '../../../utils/validation';

interface Props {
  isOrganization: boolean;
  onSubmit: (data: SignupFormData | OrganizationSignupFormData) => Promise<void>;
}

export function SignupFormFields({ isOrganization, onSubmit }: Props) {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [formData, setFormData] = useState<SignupFormData | OrganizationSignupFormData>(
    isOrganization 
      ? {
          email: '',
          password: '',
          confirmPassword: '',
          organizationName: ''
        }
      : {
          email: '',
          password: '',
          confirmPassword: '',
          organizationCodeId: ''
        }
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!acceptedTerms) {
      setError('Please accept the terms and conditions');
      return;
    }

    const validationErrors = validateSignupForm(formData);
    if (validationErrors.length > 0) {
      setError(validationErrors[0].message);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await onSubmit(formData);
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

        {isOrganization && (
          <input
            type="text"
            name="organizationName"
            value={'organizationName' in formData ? formData.organizationName : ''}
            onChange={(e) => setFormData({ ...formData, organizationName: e.target.value })}
            placeholder="Enter organization name"
            className="h-12 w-full px-4 rounded-md border border-input bg-background"
            required
          />
        )}

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
          />
          <span className="text-sm text-muted-foreground">
            By signing up, you agree to our{' '}
            <button
              type="button"
              onClick={() => navigate('/terms')}
              className="text-primary hover:underline dark:text-[#8BBFC1]"
            >
              Terms of Service
            </button>
            {' '}and{' '}
            <button
              type="button"
              onClick={() => navigate('/privacy')}
              className="text-primary hover:underline dark:text-[#8BBFC1]"
            >
              Privacy Policy
            </button>
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

      <p className="text-center text-sm">
        Already have an account?{' '}
        <button
          type="button"
          onClick={() => navigate('/')}
          className="text-primary hover:underline dark:text-[#8BBFC1]"
        >
          Sign in
        </button>
      </p>
    </form>
  );
}