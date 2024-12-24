import React, { useState } from 'react';
import { Card } from '../ui/card';

export function NotificationSettings() {
  const [notifications, setNotifications] = useState({
    subscriptionUpdates: true,
    reportGeneration: true,
    reportEdits: false,
    billingAlerts: true,
    marketingEmails: false
  });

  const handleToggle = (key: keyof typeof notifications) => {
    setNotifications(prev => ({
      ...prev,
      [key]: !prev[key]
    }));
  };

  return (
    <Card className="p-6 bg-white">
      <h2 className="text-xl font-medium text-gray-900 mb-6">Notification Preferences</h2>
      
      <div className="space-y-6">
        {Object.entries(notifications).map(([key, value]) => (
          <div key={key} className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-medium text-gray-900">
                {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
              </h3>
              <p className="text-sm text-gray-500">
                Receive notifications about {key.toLowerCase().replace(/([A-Z])/g, ' $1')}
              </p>
            </div>
            <button
              onClick={() => handleToggle(key as keyof typeof notifications)}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-[#1d7f84] focus:ring-offset-2 ${
                value ? 'bg-[#1d7f84]' : 'bg-gray-200'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  value ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        ))}
      </div>
    </Card>
  );
}