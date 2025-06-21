import React from 'react';

export const LoadingSpinner: React.FC = () => (
  <div className="min-h-screen flex items-center justify-center">
    <div className="text-center">
      <div className="relative">
        <div className="w-12 h-12 border-4 border-picton-blue/20 rounded-full animate-pulse"></div>
        <div className="absolute top-0 left-0 w-12 h-12 border-4 border-picton-blue border-t-transparent rounded-full animate-spin"></div>
      </div>
      <p className="mt-4 text-sm text-muted-foreground font-body animate-fade-in">Loading...</p>
      <span className="sr-only">Loading...</span>
    </div>
  </div>
);