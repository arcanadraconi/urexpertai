import React, { useState } from 'react';
import type { SignupFormData, OrganizationSignupFormData } from '../../types/auth.types';
import { validateSignupForm } from '../../utils/validation';

interface Props {
  isOrganization: boolean;
  error: string | null;
  loading: boolean;
  acceptedTerms: boolean;
  onAcceptTerms: (accepted: boolean) => void;
  onSubmit: (data: SignupFormData | OrganizationSignupFormData) => void;
}

export function SignupFormFields({
  isOrganization,
  error,
  loading,
  acceptedTerms,
  onAcceptTerms,
  onSubmit
}: Props) {
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
  const [showOrgId, setShowOrgId] = useState(false);
  const [validationErrors, setValidationErrors] = useState<Array<{ field: string; message: string }>>([]);

  const getError = (field: string) => 
    validationErrors.find(error => error.field === field)?.message;

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    if (type === 'checkbox') {
      if (name === 'showOrgId') {
        setShowOrgId(checked);
        if (!checked && 'organizationCodeId' in formData) {
          setFormData(prev => ({
            ...prev,
            organizationCodeId: ''
          }));
        }
      } else if (name === 'acceptTerms') {
        onAcceptTerms(checked);
      }
    } else {
      setFormData(prev => ({
        ...prev,
        [name]: value
      }));
    }
    setValidationErrors(prev => prev.filter(error => error.field !== name));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const errors = validateSignupForm(formData);
    if (errors.length > 0) {
      setValidationErrors(errors);
      return;
    }
    onSubmit(formData);
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
          onChange={handleChange}
          placeholder="Enter your email"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          autoComplete="email"
        />
        {getError('email') && (
          <p className="mt-1 text-sm text-destructive">{getError('email')}</p>
        )}

        {isOrganization && (
          <input
            type="text"
            name="organizationName"
            value={'organizationName' in formData ? formData.organizationName : ''}
            onChange={handleChange}
            placeholder="Enter organization name"
            className="h-12 w-full px-4 rounded-md border border-input bg-background"
            required
          />
        )}

        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={handleChange}
          placeholder="Create password"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          minLength={8}
        />

        <input
          type="password"
          name="confirmPassword"
          value={formData.confirmPassword}
          onChange={handleChange}
          placeholder="Confirm password"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
        />

        {!isOrganization && (
          <div className="space-y-4">
            <label className="flex items-center space-x-2">
              <input
                type="checkbox"
                name="showOrgId"
                checked={showOrgId}
                onChange={handleChange}
                className="rounded border-input h-4 w-4 text-primary focus:ring-primary"
              />
              <span className="text-sm">I have an organization code</span>
            </label>
            
            {showOrgId && (
              <input
                type="text"
                name="organizationCodeId"
                value={'organizationCodeId' in formData ? formData.organizationCodeId : ''}
                onChange={handleChange}
                placeholder="Enter organization code"
                className="h-12 w-full px-4 rounded-md border border-input bg-background"
                required
              />
            )}
          </div>
        )}

        <label className="flex items-start space-x-2">
          <input
            type="checkbox"
            name="acceptTerms"
            checked={acceptedTerms}
            onChange={handleChange}
            required
            className="rounded border-input mt-1 h-4 w-4 text-primary focus:ring-primary"
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
    </form>
  );
}