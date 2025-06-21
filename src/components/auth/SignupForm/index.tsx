import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ThemeToggle } from '../../ui/theme-toggle';
import { FeaturesPanel } from '../FeaturesPanel';
import { Logo } from '../../common/Logo';
import { OrganizationCodeSignup } from './OrganizationCodeSignup';
import { OrganizationSignup } from './OrganizationSignup';
import { UserSignup } from './UserSignup';

interface Props {
  isOrganization?: boolean;
}

export function SignupForm({ isOrganization = false }: Props) {
  const navigate = useNavigate();
  const [hasOrgCode, setHasOrgCode] = useState(false);

  return (
    <div className="min-h-screen flex">
      <FeaturesPanel />

      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 relative">
        <div className="absolute top-8 right-8">
          <ThemeToggle />
        </div>
        
        <div className="w-full max-w-md bg-[#004a4d]/15 dark:bg-white/7 rounded-xl shadow-lg p-8">
          <div className="text-center items-center space-y-2">
            <Logo />
            <h2 className="text-2xl font-medium">
              {isOrganization ? 'Create Organization' : 'Create Account'}
            </h2>
            <p className="text-sm text-muted-foreground">
              {isOrganization 
                ? 'Set up your organization account'
                : hasOrgCode 
                  ? 'Join an existing organization'
                  : 'Enter your details to get started'
              }
            </p>
          </div>

          {isOrganization ? (
            <OrganizationSignup />
          ) : hasOrgCode ? (
            <OrganizationCodeSignup />
          ) : (
            <div>
              <UserSignup onHasOrgCode={() => setHasOrgCode(true)} />
              <div className="mt-4 text-center">
                <p className="text-sm text-muted-foreground">
                  Want to create an organization?{' '}
                  <button
                    onClick={() => navigate('/signup/organization')}
                    className="text-primary hover:underline dark:text-[#8BBFC1]"
                    type="button"
                  >
                    Create Organization
                  </button>
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
