import React, { useState, forwardRef } from 'react';
import type { ProcessedReport } from '../../types/report.types';

interface Props {
  report: ProcessedReport;
  onSave: (updates: Partial<ProcessedReport>) => Promise<void>;
}

export const ReportContent = forwardRef<HTMLDivElement, Props>(({ report, onSave }, ref) => {
  const [content, setContent] = useState(report.content);
  const [autoSaveTimeout, setAutoSaveTimeout] = useState<NodeJS.Timeout>();

  const handleChange = (field: keyof ProcessedReport['content'], value: string) => {
    const newContent = { ...content, [field]: value };
    setContent(newContent);

    // Clear existing timeout
    if (autoSaveTimeout) {
      clearTimeout(autoSaveTimeout);
    }

    // Set new timeout for auto-save
    const timeout = setTimeout(() => {
      onSave({ content: newContent });
    }, 1000);
    setAutoSaveTimeout(timeout);
  };

  return (
    <div ref={ref} className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-gray-700">Diagnosis</label>
        <textarea
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          rows={3}
          value={content.diagnosis}
          onChange={e => handleChange('diagnosis', e.target.value)}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Treatment Plan</label>
        <textarea
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          rows={3}
          value={content.treatmentPlan}
          onChange={e => handleChange('treatmentPlan', e.target.value)}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Medical Necessity</label>
        <textarea
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          rows={3}
          value={content.medicalNecessity}
          onChange={e => handleChange('medicalNecessity', e.target.value)}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Clinical Findings</label>
        <textarea
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          rows={4}
          value={content.clinicalFindings}
          onChange={e => handleChange('clinicalFindings', e.target.value)}
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Recommendations</label>
        <textarea
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          rows={3}
          value={content.recommendations}
          onChange={e => handleChange('recommendations', e.target.value)}
        />
      </div>
    </div>
  );
});