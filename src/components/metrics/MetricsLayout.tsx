import React from 'react';
import { BarChart2, TrendingUp, Clock, Download } from 'lucide-react';
import { Card } from '../ui/card';

export function MetricsLayout() {
  // Sample data - in a real app, this would come from your backend
  const metrics = {
    totalReviews: 156,
    monthToDate: 23,
    avgGenerationTime: '45 seconds',
    totalEdits: 89,
    previousPeriod: {
      totalReviews: 142,
      monthToDate: 19
    }
  };

  const calculatePercentageChange = (current: number, previous: number) => {
    const change = ((current - previous) / previous) * 100;
    return change.toFixed(1);
  };

  return (
    <div className="w-full max-w-6xl mx-auto p-6">
      <h1 className="text-3xl font-light text-[#1d7f84] mb-8">Metrics & Analytics</h1>
      
      {/* Key Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card className="p-6 bg-white">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Reviews</p>
              <h3 className="text-2xl font-semibold mt-1">{metrics.totalReviews}</h3>
            </div>
            <div className="p-2 bg-[#1d7f84]/10 rounded-lg">
              <BarChart2 className="w-5 h-5 text-[#1d7f84]" />
            </div>
          </div>
        </Card>

        <Card className="p-6 bg-white">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500">Month to Date</p>
              <h3 className="text-2xl font-semibold mt-1">{metrics.monthToDate}</h3>
              <p className="text-xs text-green-600 mt-1">
                <TrendingUp className="w-3 h-3 inline mr-1" />
                {calculatePercentageChange(metrics.monthToDate, metrics.previousPeriod.monthToDate)}% vs last month
              </p>
            </div>
            <div className="p-2 bg-[#1d7f84]/10 rounded-lg">
              <TrendingUp className="w-5 h-5 text-[#1d7f84]" />
            </div>
          </div>
        </Card>

        <Card className="p-6 bg-white">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500">Avg. Generation Time</p>
              <h3 className="text-2xl font-semibold mt-1">{metrics.avgGenerationTime}</h3>
            </div>
            <div className="p-2 bg-[#1d7f84]/10 rounded-lg">
              <Clock className="w-5 h-5 text-[#1d7f84]" />
            </div>
          </div>
        </Card>

        <Card className="p-6 bg-white">
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Edits</p>
              <h3 className="text-2xl font-semibold mt-1">{metrics.totalEdits}</h3>
            </div>
            <div className="p-2 bg-[#1d7f84]/10 rounded-lg">
              <Download className="w-5 h-5 text-[#1d7f84]" />
            </div>
          </div>
        </Card>
      </div>

      {/* Chart Section */}
      <Card className="p-6 bg-white mb-8">
        <h2 className="text-lg font-semibold mb-4">Reports Generated Over Time</h2>
        <div className="h-[300px] flex items-center justify-center text-gray-500">
          Chart will be displayed here
        </div>
      </Card>

      {/* Download Report Button */}
      <div className="flex justify-end">
        <button 
          onClick={() => {/* Handle download */}}
          className="flex items-center px-4 py-2 bg-[#1d7f84] text-white rounded-md hover:bg-[#1d7f84]/90 transition-colors"
        >
          <Download className="w-4 h-4 mr-2" />
          Download Metrics Report
        </button>
      </div>
    </div>
  );
}