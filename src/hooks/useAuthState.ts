import { useState } from 'react';
import type { SignupFormData, OrganizationSignupFormData, LoginFormData } from '../types/auth';
import { ApiService } from '../utils/api';

export function useAuthState() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [emailVerified, setEmailVerified] = useState(false);
  const [userEmail, setUserEmail] = useState('');

  const handleSignup = async (data: SignupFormData | OrganizationSignupFormData) => {
    try {
      const response = await ApiService.signup(data);
      localStorage.setItem('token', response.access_token);
      setUserEmail(data.email);
      setIsAuthenticated(true);
      setEmailVerified(false);
      return response;
    } catch (error) {
      console.error('Signup error:', error);
      throw error;
    }
  };

  const handleLogin = async (data: LoginFormData) => {
    try {
      const response = await ApiService.login(data.email, data.password);
      localStorage.setItem('token', response.access_token);
      setIsAuthenticated(true);
      setEmailVerified(response.user.email_verified);
      setUserEmail(response.user.email);
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  };

  return {
    isAuthenticated,
    emailVerified,
    userEmail,
    setEmailVerified,
    setIsAuthenticated,
    handleSignup,
    handleLogin
  };
}