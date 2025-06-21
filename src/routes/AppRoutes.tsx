import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { LoginForm } from '../components/auth/LoginForm';
import { SignupForm } from '../components/auth/SignupForm/index';
import { VerifyEmail } from '../components/auth/VerifyEmail';
import Dashboard from '../components/dashboard';

export function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<LoginForm />} />
      <Route path="/signup" element={<SignupForm />} />
      <Route path="/signup/organization" element={<SignupForm isOrganization />} />
      <Route path="/verify-email" element={<VerifyEmail />} />
      <Route path="/verify-email/:id" element={<VerifyEmail />} />
      <Route path="/dashboard" element={<Dashboard />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
