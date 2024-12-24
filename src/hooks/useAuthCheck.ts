import { useEffect } from 'react';
import { ApiService } from '../utils/api';

interface UseAuthCheckProps {
  setIsAuthenticated: (value: boolean) => void;
  setEmailVerified: (value: boolean) => void;
  setUserEmail: (value: string) => void;
  setLoading: (value: boolean) => void;
}

export function useAuthCheck({
  setIsAuthenticated,
  setEmailVerified,
  setUserEmail,
  setLoading
}: UseAuthCheckProps) {
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
  }, [setIsAuthenticated, setEmailVerified, setUserEmail, setLoading]);
}