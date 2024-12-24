export interface SignupFormData {
  email: string;
  password: string;
  confirmPassword: string;
  organizationCodeId?: string;
}

export interface OrganizationSignupFormData {
  email: string;
  password: string;
  confirmPassword: string;
  organizationName: string;
}

export interface LoginFormData {
  email: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  user: {
    id: string;
    email: string;
    email_verified: boolean;
  };
}

export interface TokenVerificationResponse {
  valid: boolean;
  user?: {
    id: string;
    email: string;
    email_verified: boolean;
  };
}

export interface UserResponse {
  id: string;
  email: string;
  email_verified: boolean;
  role: string;
}