import React from 'react';
import logoImage from './urexpertai.png';

interface LogoProps {
  className?: string;
}

export function Logo({ className = "h-24 w-auto" }: LogoProps) {
  return (
    <img 
      src={logoImage}
      alt="URExpert Logo"
      className={className}
    />
  );
}
