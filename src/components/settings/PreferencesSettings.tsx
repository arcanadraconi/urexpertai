import React, { useState } from 'react';
import { Card } from '../ui/card';
import { Moon, Sun } from 'lucide-react';

export function PreferencesSettings() {
  const [preferences, setPreferences] = useState({
    theme: 'light',
    defaultTimeRange: '30',
    language: 'en'
  });

  const handleChange = (key: keyof typeof preferences, value: string) => {
    setPreferences(prev => ({
      ...prev,
      [key]: value
    }));
  };

  return (
    <div className="space-y-6">
      <Card className="p-6 bg-white">
        <h2 className="text-xl font-medium text-gray-900 mb-6">Display Settings</h2>
        
        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Theme</label>
            <div className="flex space-x-4">
              {['light', 'dark', 'system'].map((theme) => (
                <button
                  key={theme}
                  onClick={() => handleChange('theme', theme)}
                  className={`flex items-center px-4 py-2 rounded-md ${
                    preferences.theme === theme
                      ? 'bg-[#1d7f84] text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {theme === 'light' && <Sun className="w-4 h-4 mr-2" />}
                  {theme === 'dark' && <Moon className="w-4 h-4 mr-2" />}
                  {theme.charAt(0).toUpperCase() + theme.slice(1)}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Default Time Range for Metrics
            </label>
            <select
              value={preferences.defaultTimeRange}
              onChange={(e) => handleChange('defaultTimeRange', e.target.value)}
              className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-[#1d7f84] focus:border-[#1d7f84] sm:text-sm rounded-md text-gray-700"
            >
              <option value="7">Last 7 days</option>
              <option value="30">Last 30 days</option>
              <option value="90">Last 90 days</option>
              <option value="365">Last year</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Language
            </label>
            <select
              value={preferences.language}
              onChange={(e) => handleChange('language', e.target.value)}
              className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-[#1d7f84] focus:border-[#1d7f84] sm:text-sm rounded-md text-gray-700"
            >
              <option value="en">English</option>
              <option value="es">Español</option>
              <option value="fr">Français</option>
            </select>
          </div>
        </div>
      </Card>

      <Card className="p-6 bg-white">
        <h2 className="text-xl font-medium text-gray-900 mb-6">Data & Privacy</h2>
        
        <div className="space-y-4">
          <button className="text-[#1d7f84] hover:underline text-sm">
            Download my data
          </button>
          <button className="text-[#1d7f84] hover:underline text-sm">
            View privacy policy
          </button>
          <button className="text-red-500 hover:underline text-sm">
            Delete my account
          </button>
        </div>
      </Card>
    </div>
  );
}