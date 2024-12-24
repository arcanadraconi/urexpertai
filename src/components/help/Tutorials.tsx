import React from 'react';
import { Play, FileText } from 'lucide-react';
import { Card } from '../ui/card';

const tutorials = [
  {
    title: "Getting Started with URExpert",
    description: "Learn the basics of using URExpert for medical report generation.",
    duration: "5 min",
    type: "video"
  },
  {
    title: "Manual Data Entry Guide",
    description: "Step-by-step guide for entering patient data manually.",
    duration: "3 min",
    type: "article"
  },
  {
    title: "Editing and Customizing Reports",
    description: "Learn how to modify and customize generated reports.",
    duration: "4 min",
    type: "video"
  }
];

export function Tutorials() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {tutorials.map((tutorial, index) => (
        <Card key={index} className="p-6 bg-white hover:shadow-md transition-shadow">
          <div className="flex items-start justify-between mb-4">
            <div className="p-2 bg-[#1d7f84]/10 rounded-lg">
              {tutorial.type === 'video' ? (
                <Play className="w-5 h-5 text-[#1d7f84]" />
              ) : (
                <FileText className="w-5 h-5 text-[#1d7f84]" />
              )}
            </div>
            <span className="text-sm text-gray-500">{tutorial.duration}</span>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">{tutorial.title}</h3>
          <p className="text-gray-600 text-sm">{tutorial.description}</p>
          <button className="mt-4 text-[#1d7f84] text-sm font-medium hover:underline">
            {tutorial.type === 'video' ? 'Watch Tutorial' : 'Read Article'}
          </button>
        </Card>
      ))}
    </div>
  );
}