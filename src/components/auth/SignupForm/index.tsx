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
  const [hasOrgCode, setHasOrgCode] = useState(false);

  return (
    <div className="min-h-screen flex">
      <FeaturesPanel />

      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 relative">
        <div className="absolute top-8 right-8">
          <ThemeToggle />
        </div>
        
        <div className="w-full max-w-md bg-[#004a4d]/15 dark:bg-white/7 rounded-xl shadow-lg p-8">
          <div className="text-center  items-center  space-y-2">
            <Logo />
            <h2 className="text-2xl font-medium">
              {isOrganization ? 'Organization Signup' : 'Create Account'}
            </h2>
            <p className="text-sm text-muted-foreground">
              Enter your details to get started
            </p>
          </div>

          {isOrganization ? (
            <OrganizationSignup />
          ) : hasOrgCode ? (
            <OrganizationCodeSignup />
          ) : (
            <UserSignup onHasOrgCode={() => setHasOrgCode(true)} />
          )}
        </div>
      </div>
    </div>
  );
}