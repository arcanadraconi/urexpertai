// Core Auth Types
export interface AuthResponse {
  accessToken: string;
  user: {
    id: string;
    email: string;
    emailVerified: boolean;
  };
}

export interface TokenResponse {
  valid: boolean;
  user?: {
    id: string;
    email: string;
    emailVerified: boolean;
  };
}

export interface UserResponse {
  id: string;
  email: string;
  emailVerified: boolean;
  role: string;
}

// Signup Types
export interface SignupData {
  email: string;
  password: string;
  role: string;
  organizationId?: string;
}

export interface OrganizationSignupData {
  email: string;
  password: string;
  organizationName: string;
}

export interface SignupResponse {
  accessToken: string;
  user: {
    id: string;
    email: string;
    emailVerified: boolean;
    role: string;
  };
}

// Verification Types
export interface VerificationResponse {
  verified: boolean;
  message?: string;
}