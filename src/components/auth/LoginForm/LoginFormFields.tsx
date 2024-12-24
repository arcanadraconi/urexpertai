import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import type { LoginFormData } from '../../../types/auth.types';

interface Props {
  onSubmit: (data: LoginFormData) => Promise<void>;
  error: string | null;
  loading: boolean;
}

export function LoginFormFields({ onSubmit, error, loading }: Props) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState<LoginFormData>({
    email: '',
    password: '',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="mt-8 space-y-4">
      {error && (
        <div className="p-3 text-sm rounded-md bg-destructive/10 text-destructive">
          {error}
        </div>
      )}

      <div className="space-y-4">
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          placeholder="Enter your email"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          autoComplete="email"
        />

        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={handleChange}
          placeholder="Enter your password"
          className="h-12 w-full px-4 rounded-md border border-input bg-background"
          required
          autoComplete="current-password"
        />

        <div className="flex items-center justify-between text-sm">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              className="rounded border-input h-4 w-4 text-primary focus:ring-primary"
            />
            <span>Remember me</span>
          </label>

          <a
            href="/forgot-password"
            className="text-primary hover:underline dark:text-[#8BBFC1]"
          >
            Forgot Password?
          </a>
        </div>
      </div>

      <button
        type="submit"
        className="w-full h-12 text-base gradient-primary hover:opacity-90 transition-opacity text-white rounded-md font-medium"
        disabled={loading}
      >
        {loading ? 'Signing in...' : 'CONTINUE'}
      </button>

      <p className="text-center text-sm">
        Don't have an account?{' '}
        <button
          onClick={() => navigate('/signup')}
          className="text-primary hover:underline dark:text-[#8BBFC1]"
          type="button"
        >
          Sign up
        </button>
      </p>
    </form>
  );
}