import { AuthError } from '@supabase/supabase-js';

export class SignupError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = 'SignupError';
  }
}

export function handleAuthError(error: unknown): SignupError {
  console.error('Auth error:', error);

  if (error instanceof AuthError) {
    switch (error.status) {
      case 400:
        return new SignupError('Invalid email or password format', 'INVALID_FORMAT');
      case 422:
        return new SignupError('Email already registered', 'EMAIL_EXISTS');
      case 500:
        if (error.message.includes('Database error')) {
          return new SignupError('Failed to create organization. Please try again.', 'DATABASE_ERROR');
        }
        return new SignupError('Server error during signup. Please try again later.', 'SERVER_ERROR');
      default:
        return new SignupError('An unexpected error occurred. Please try again.', 'UNKNOWN');
    }
  }

  if (error instanceof Error) {
    if (error.message.includes('organization')) {
      return new SignupError('Failed to create organization. Please try again.', 'ORG_CREATE_FAILED');
    }
    if (error.message.includes('Invalid organization code')) {
      return new SignupError('Invalid organization code. Please check and try again.', 'INVALID_ORG_CODE');
    }
    return new SignupError(error.message, 'UNKNOWN');
  }

  return new SignupError('An unexpected error occurred. Please try again.', 'UNKNOWN');
}