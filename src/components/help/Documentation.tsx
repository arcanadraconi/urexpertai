import React from 'react';
import { Card } from '../ui/card';
import { Search } from 'lucide-react';

export function Documentation() {
  return (
    <div className="space-y-8">
      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input
          type="search"
          placeholder="Search documentation..."
          className="w-full pl-12 pr-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-[#1d7f84] focus:border-transparent"
        />
      </div>

      {/* Documentation Sections */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="p-6 bg-white">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Getting Started</h3>
          <ul className="space-y-3">
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Introduction to URExpert</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">System Requirements</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Quick Start Guide</a>
            </li>
          </ul>
        </Card>

        <Card className="p-6 bg-white">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Features</h3>
          <ul className="space-y-3">
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Report Generation</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Manual Data Entry</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Data Security</a>
            </li>
          </ul>
        </Card>

        <Card className="p-6 bg-white">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Troubleshooting</h3>
          <ul className="space-y-3">
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Common Issues</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Error Messages</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">System Status</a>
            </li>
          </ul>
        </Card>

        <Card className="p-6 bg-white">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Best Practices</h3>
          <ul className="space-y-3">
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Data Entry Guidelines</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Report Customization</a>
            </li>
            <li>
              <a href="#" className="text-[#1d7f84] hover:underline">Security Recommendations</a>
            </li>
          </ul>
        </Card>
      </div>
    </div>
  );
}