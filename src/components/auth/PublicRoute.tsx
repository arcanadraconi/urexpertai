import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

interface PublicRouteProps {
  children: React.ReactNode;
}

export const PublicRoute: React.FC<PublicRouteProps> = ({ children }) => {
  const { isAuthenticated, emailVerified } = useAuth();

  if (isAuthenticated) {
    return <Navigate to={emailVerified ? "/dashboard" : "/verify-email"} />;
  }

  return <>{children}</>;
};