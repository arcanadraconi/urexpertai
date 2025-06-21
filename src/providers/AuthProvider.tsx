import React, { useState, useEffect } from 'react';
import { AuthContext } from '../contexts/AuthContext';
import { ApiService } from '../utils/api';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [emailVerified, setEmailVerified] = useState<boolean>(false);
  const [userEmail, setUserEmail] = useState<string>('');

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('token');
        if (token) {
          const response = await ApiService.verifyToken();
          setIsAuthenticated(response.valid);
          if (response.valid) {
            const userResponse = await ApiService.getCurrentUser();
            setEmailVerified(userResponse.email_verified);
            setUserEmail(userResponse.email);
          }
        } else {
          setIsAuthenticated(false);
        }
      } catch (error) {
        console.error('Auth check failed:', error);
        localStorage.removeItem('token');
        setIsAuthenticated(false);
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, []);

  const value = {
    isAuthenticated,
    emailVerified,
    userEmail,
    setEmailVerified,
    setIsAuthenticated
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center">
      <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
    </div>;
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};