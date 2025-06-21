interface BaseSignupFormData {
  email: string;
  password: string;
  confirmPassword: string;
}

export interface UserSignupFormData extends BaseSignupFormData {}

export type SignupFormData = UserSignupFormData | OrganizationSignupFormData | OrganizationCodeSignupFormData;

export interface OrganizationSignupFormData extends BaseSignupFormData {
  organizationName: string;
}

export interface OrganizationCodeSignupFormData extends BaseSignupFormData {
  organizationCode: string;
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
  role?: string;
}
