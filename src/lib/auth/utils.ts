import type { AuthResponse, SignupResponse } from './types';

export function mapAuthResponse(data: any): AuthResponse {
  return {
    accessToken: data.session?.access_token || '',
    user: {
      id: data.user?.id || '',
      email: data.user?.email || '',
      emailVerified: data.user?.email_confirmed_at != null
    }
  };
}

export function mapSignupResponse(data: any): SignupResponse {
  return {
    accessToken: data.session?.access_token || '',
    user: {
      id: data.user?.id || '',
      email: data.user?.email || '',
      emailVerified: data.user?.email_confirmed_at != null,
      role: data.user?.user_metadata?.role || 'user'
    }
  };
}