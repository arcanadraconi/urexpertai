import { Outlet } from 'react-router-dom';
import { FileText } from 'lucide-react';
import { ThemeToggle } from '../ui/theme-toggle';

export function AuthLayout() {
  return (
    <div className="min-h-screen transition-colors duration-300 bg-lavender-web dark:bg-gradient-dark">
      <div className="absolute top-4 right-4 z-10">
        <ThemeToggle />
      </div>
      
      <div className="flex min-h-screen">
        {/* Left side - Branding */}
        <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-picton-blue to-lapis-lazuli opacity-90"></div>
          <div className="relative z-10 p-12 flex flex-col justify-between">
            <div className="animate-fade-in-down">
              <div className="flex items-center space-x-3">
                <div className="p-3 bg-white/20 backdrop-blur-sm rounded-xl">
                  <FileText className="h-8 w-8 text-white" />
                </div>
                <span className="text-2xl font-bold text-white font-title">ChartExpert</span>
              </div>
              <div className="mt-16">
                <h1 className="text-4xl lg:text-5xl font-bold text-white font-title leading-tight">
                  Streamline Your Medical Documentation
                </h1>
                <p className="mt-6 text-lg text-white/90 font-body">
                  Efficient, accurate, and compliant medical report generation for healthcare professionals.
                </p>
              </div>
            </div>
            
            <div className="space-y-6 animate-fade-in-up">
              <div className="grid grid-cols-2 gap-4">
                <div className="glass-card p-4 bg-white/10">
                  <h3 className="font-title font-semibold text-white mb-2">Fast & Accurate</h3>
                  <p className="text-sm text-white/80 font-body">Generate reports in seconds with AI-powered assistance</p>
                </div>
                <div className="glass-card p-4 bg-white/10">
                  <h3 className="font-title font-semibold text-white mb-2">HIPAA Compliant</h3>
                  <p className="text-sm text-white/80 font-body">Enterprise-grade security for patient data</p>
                </div>
              </div>
              
              <div className="text-sm text-white/60 font-body">
                © {new Date().getFullYear()} ChartExpert. All rights reserved.
              </div>
            </div>
          </div>
        </div>

        {/* Right side - Auth forms */}
        <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
          <div className="w-full max-w-md animate-fade-in">
            <Outlet />
          </div>
        </div>
      </div>
    </div>
  );
}