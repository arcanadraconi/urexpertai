import React from 'react';
import { Clock } from 'lucide-react';

export function ActivityLog() {
  const activities = [
    {
      id: 1,
      action: 'Generated Report',
      timestamp: '2024-03-24T10:30:00Z',
      details: 'Created medical report for patient #12345'
    },
    {
      id: 2,
      action: 'Updated Profile',
      timestamp: '2024-03-23T15:45:00Z',
      details: 'Changed profile information'
    },
    // Add more activities as needed
  ];

  return (
    <div className="bg-white rounded-lg shadow-sm p-8">
      <div className="space-y-6">
        {activities.map((activity) => (
          <div key={activity.id} className="flex items-start gap-4 pb-6 border-b border-gray-100 last:border-0">
            <div className="p-2 bg-[#1d7f84]/10 rounded-full">
              <Clock className="w-5 h-5 text-[#1d7f84]" />
            </div>
            <div>
              <h3 className="font-medium text-gray-900">{activity.action}</h3>
              <p className="text-sm text-gray-500">{activity.details}</p>
              <time className="text-xs text-gray-400 mt-1">
                {new Date(activity.timestamp).toLocaleString()}
              </time>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}