import React from 'react';

interface LogoProps {
  className?: string;
}

export function Logo({ className = "h-24 w-auto" }: LogoProps) {
  return (
    <img 
      src="urexpertai.png"
      alt="URExpert Logo"
      className={className}
    />
  );
}