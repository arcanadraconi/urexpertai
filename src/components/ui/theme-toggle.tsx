import React from 'react';
import { Moon, Sun } from 'lucide-react';
import { useTheme } from '../../providers/theme-provider';

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
  };

  return (
    <button
      onClick={toggleTheme}
      className="p-2.5 rounded-xl glass-card-subtle hover:scale-105 transition-all duration-300 group"
      aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {theme === 'dark' ? (
        <Sun className="h-5 w-5 text-picton-blue group-hover:rotate-180 transition-transform duration-500" />
      ) : (
        <Moon className="h-5 w-5 text-russian-violet group-hover:-rotate-12 transition-transform duration-500" />
      )}
    </button>
  );
}