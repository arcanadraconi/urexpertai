import React from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { ThemeToggle } from '../ui/theme-toggle';
import { FeaturesPanel } from './features-panel';
import { VerifyEmailContent } from './verify-email-content';

export function VerifyEmail() {
  const { id } = useParams();
  const location = useLocation();
  const email = location.state?.email;

  return (
    <div className="min-h-screen flex">
      <FeaturesPanel />

      <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
        <div className="absolute top-8 right-8">
          <ThemeToggle />
        </div>
        
        <div className="w-full max-w-md bg-[#004a4d]/15 dark:bg-white/[0.07] rounded-xl shadow-lg p-8">
          <div className="flex flex-col items-center space-y-4">
            <img 
              src="/urexpertlogo.png" 
              alt="URExpert Logo" 
              className="h-24 w-auto"
            />
            
            <VerifyEmailContent verificationId={id} email={email} />
          </div>
        </div>
      </div>
    </div>
  );
}