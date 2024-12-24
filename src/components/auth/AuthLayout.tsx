import React from 'react';
import { Outlet } from 'react-router-dom';
import { FileText } from 'lucide-react';

export function AuthLayout() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50">
      <div className="flex min-h-screen">
        {/* Left side - Branding */}
        <div className="hidden lg:flex lg:w-1/2 bg-blue-600 p-12 flex-col justify-between">
          <div>
            <div className="flex items-center space-x-3">
              <FileText className="h-8 w-8 text-white" />
              <span className="text-2xl font-bold text-white">URExpert</span>
            </div>
            <div className="mt-16">
              <h1 className="text-4xl font-bold text-white">
                Streamline Your Medical Documentation
              </h1>
              <p className="mt-4 text-lg text-blue-100">
                Efficient, accurate, and compliant medical report generation for healthcare professionals.
              </p>
            </div>
          </div>
          <div className="text-sm text-blue-100">
            © {new Date().getFullYear()} URExpert. All rights reserved.
          </div>
        </div>

        {/* Right side - Auth forms */}
        <div className="w-full lg:w-1/2">
          <Outlet />
        </div>
      </div>
    </div>
  );
}