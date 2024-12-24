import React, { useState, useEffect } from 'react';
import { Mail, CheckCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { verificationService } from '../../lib/auth/verification-service';

interface Props {
  verificationId?: string;
  email?: string;
}

export function VerifyEmailContent({ verificationId, email }: Props) {
  const navigate = useNavigate();
  const [verifying, setVerifying] = useState(false);
  const [verified, setVerified] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [resending, setResending] = useState(false);

  useEffect(() => {
    if (verificationId) {
      handleVerification();
    }
  }, [verificationId]);

  const handleVerification = async () => {
    if (!verificationId) return;
    
    setVerifying(true);
    try {
      const response = await verificationService.verifyEmail(verificationId);
      if (response.verified) {
        setVerified(true);
        setTimeout(() => {
          navigate('/dashboard');
        }, 2000);
      } else {
        setError('Email verification failed. Please try again.');
      }
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to verify email');
    } finally {
      setVerifying(false);
    }
  };

  const handleResendVerification = async () => {
    if (!email) {
      setError('No email address provided');
      return;
    }

    setResending(true);
    setError(null);
    
    try {
      const response = await verificationService.resendVerification(email);
      setError('Verification email sent! Please check your inbox.');
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to resend verification email');
    } finally {
      setResending(false);
    }
  };

  return (
    <div className="text-center space-y-4">
      {verifying ? (
        <div className="flex flex-col items-center gap-4">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          <p className="text-2xl font-semibold">Verifying your email...</p>
        </div>
      ) : verified ? (
        <div className="space-y-4">
          <div className="rounded-full bg-green-100 p-3 mx-auto w-fit">
            <CheckCircle className="h-6 w-6 text-green-600" />
          </div>
          <h1 className="text-2xl font-normal">Email Verified!</h1>
          <p className="text-muted-foreground">
            Your email has been verified successfully. Redirecting to dashboard...
          </p>
        </div>
      ) : (
        <>
          <div className="rounded-full bg-blue-100 p-3 mx-auto w-fit">
            <Mail className="h-6 w-6 text-blue-600" />
          </div>

          <h1 className="text-2xl font-normal">Verify your email</h1>
          
          <p className="text-muted-foreground max-w-sm">
            We've sent a verification link to <span className="font-medium">{email}</span>. 
            Please check your inbox and click the link to verify your account.
          </p>

          {error && (
            <p className={`text-sm ${error.includes('sent') ? 'text-green-600' : 'text-destructive'}`}>
              {error}
            </p>
          )}

          <button 
            className="w-full h-12 text-base border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md"
            onClick={handleResendVerification}
            disabled={resending}
          >
            {resending ? 'Sending...' : 'Resend verification email'}
          </button>

          <p className="text-sm text-muted-foreground">
            Didn't receive an email? Check your spam folder or try resending the verification email.
          </p>
        </>
      )}
    </div>
  );
}