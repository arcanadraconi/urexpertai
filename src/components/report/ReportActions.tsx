import React, { useRef } from 'react';
import { Download, Save } from 'lucide-react';
import type { ProcessedReport } from '../../types/report.types';
import { pdfGenerator } from '../../lib/pdfGenerator';

interface Props {
  report: ProcessedReport;
  saving: boolean;
  onSave: (updates: Partial<ProcessedReport>) => Promise<void>;
}

export function ReportActions({ report, saving, onSave }: Props) {
  const contentRef = useRef<HTMLDivElement>(null);

  const handleSubmit = () => {
    onSave({ status: 'submitted' });
  };

  const handleDownload = async () => {
    if (!contentRef.current) return;

    try {
      const blob = await pdfGenerator.generateReportPDF(report, contentRef.current);
      const url = URL.createObjectURL(blob);
      
      // Create temporary link and trigger download
      const link = document.createElement('a');
      link.href = url;
      link.download = `report-${report.id}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      // Clean up
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error generating PDF:', error);
      // TODO: Add error handling UI
    }
  };

  return (
    <div className="mt-6 flex justify-end space-x-4">
      <button
        onClick={handleDownload}
        className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
      >
        <Download className="h-4 w-4 mr-2" />
        Download PDF
      </button>

      <button
        onClick={handleSubmit}
        disabled={saving || report.status !== 'draft'}
        className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
      >
        <Save className="h-4 w-4 mr-2" />
        {saving ? 'Saving...' : 'Submit Report'}
      </button>
    </div>
  );
}