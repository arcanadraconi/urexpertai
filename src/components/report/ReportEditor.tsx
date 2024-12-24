import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import type { ProcessedReport } from '../../types/report.types';
import { reportService } from '../../lib/reportService';
import { ReportContent } from './ReportContent';
import { ReportActions } from './ReportActions';

export function ReportEditor() {
  const { id } = useParams<{ id: string }>();
  const [report, setReport] = useState<ProcessedReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (id) {
      loadReport(id);
    }
  }, [id]);

  const loadReport = async (reportId: string) => {
    try {
      const data = await reportService.getReport(reportId);
      setReport(data);
    } catch (error) {
      console.error('Error loading report:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (updates: Partial<ProcessedReport>) => {
    if (!id || !report) return;
    setSaving(true);
    try {
      const updated = await reportService.updateReport(id, updates);
      setReport(updated);
    } catch (error) {
      console.error('Error saving report:', error);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div>Loading...</div>;
  if (!report) return <div>Report not found</div>;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <ReportContent report={report} onSave={handleSave} />
      <ReportActions report={report} saving={saving} onSave={handleSave} />
    </div>
  );
}