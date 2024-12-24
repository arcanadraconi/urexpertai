import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ThemeToggle } from '../ui/theme-toggle';
import { FeaturesPanel } from './features-panel';
import type { SignupFormData, OrganizationSignupFormData } from '../../types/auth.types';

interface Props {
  isOrganization?: boolean;
  onSubmit: (data: SignupFormData | OrganizationSignupFormData) => Promise<void>;
}

export function SignupForm({ isOrganization = false, onSubmit }: Props) {
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

    setLoading(true);
    try {
      await onSubmit(formData);
      navigate('/verify-email', { state: { email: formData.email } });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create account');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      <FeaturesPanel />

      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 relative">
        <div className="absolute top-8 right-8">
          <ThemeToggle />
        </div>
        
        <div className="w-full max-w-md bg-[#004a4d]/15 dark:bg-white/7 rounded-xl shadow-lg p-8">
          <div className="text-center space-y-2">
            <img 
              src="https://i.ibb.co/TYdFmjY/urexpertlogo-3.png" 
              alt="URExpert Logo" 
              className="h-24 mx-auto mb-4"
            />
            <h2 className="text-2xl font-medium">
              {isOrganization ? 'Organization Signup' : 'Create Account'}
            </h2>
            <p className="text-sm text-muted-foreground">
              Enter your details to get started
            </p>
          </div>

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

              {!isOrganization && (
                <div className="space-y-4">
                  <label className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      name="showOrgId"
                      checked={'organizationCodeId' in formData && !!formData.organizationCodeId}
                      onChange={(e) => {
                        if (!e.target.checked && 'organizationCodeId' in formData) {
                          setFormData({ ...formData, organizationCodeId: '' });
                        }
                      }}
                      className="rounded border-input h-4 w-4 text-primary focus:ring-primary"
                    />
                    <span className="text-sm">I have an organization code</span>
                  </label>
                  
                  {('organizationCodeId' in formData && formData.organizationCodeId !== undefined) && (
                    <input
                      type="text"
                      name="organizationCodeId"
                      value={formData.organizationCodeId}
                      onChange={(e) => setFormData({ ...formData, organizationCodeId: e.target.value })}
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
                  onChange={(e) => setAcceptedTerms(e.target.checked)}
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

            <div className="space-y-2 text-center text-sm">
              <p>
                Already have an account?{' '}
                <button
                  onClick={() => navigate('/login')}
                  className="text-primary hover:underline dark:text-[#8BBFC1]"
                  type="button"
                >
                  Sign in
                </button>
              </p>

              {!isOrganization && (
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
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}