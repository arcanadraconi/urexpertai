import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import type { ManualEntryData } from '../types/report.types';
import { reportService } from '../lib/reportService';

export function ManualEntryForm() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<ManualEntryData>({
    patientInfo: {
      name: '',
      dateOfBirth: '',
      gender: '',
    },
    clinicalData: {}
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const report = await reportService.processManualEntry(data);
      navigate(`/reports/${report.id}`);
    } catch (error) {
      console.error('Error processing manual entry:', error);
      // TODO: Add error handling UI
    } finally {
      setLoading(false);
    }
  };

  const updatePatientInfo = (field: keyof ManualEntryData['patientInfo'], value: string) => {
    setData(prev => ({
      ...prev,
      patientInfo: { ...prev.patientInfo, [field]: value }
    }));
  };

  const updateClinicalData = (field: keyof ManualEntryData['clinicalData'], value: string) => {
    setData(prev => ({
      ...prev,
      clinicalData: { ...prev.clinicalData, [field]: value }
    }));
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-4xl mx-auto p-6">
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Patient Information</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">MRN (Optional)</label>
            <input
              type="text"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              value={data.patientInfo.mrn || ''}
              onChange={e => updatePatientInfo('mrn', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Full Name</label>
            <input
              type="text"
              required
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              value={data.patientInfo.name}
              onChange={e => updatePatientInfo('name', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Date of Birth</label>
            <input
              type="date"
              required
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              value={data.patientInfo.dateOfBirth}
              onChange={e => updatePatientInfo('dateOfBirth', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Gender</label>
            <select
              required
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              value={data.patientInfo.gender}
              onChange={e => updatePatientInfo('gender', e.target.value)}
            >
              <option value="">Select gender</option>
              <option value="male">Male</option>
              <option value="female">Female</option>
              <option value="other">Other</option>
            </select>
          </div>
        </div>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Clinical Information</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Chief Complaint</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.chiefComplaint || ''}
              onChange={e => updateClinicalData('chiefComplaint', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Present Illness</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.presentIllness || ''}
              onChange={e => updateClinicalData('presentIllness', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Physical Examination</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.physicalExam || ''}
              onChange={e => updateClinicalData('physicalExam', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Past Medical History</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.pastHistory || ''}
              onChange={e => updateClinicalData('pastHistory', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Medications</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.medications || ''}
              onChange={e => updateClinicalData('medications', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Allergies</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={2}
              value={data.clinicalData.allergies || ''}
              onChange={e => updateClinicalData('allergies', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Assessment</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.assessment || ''}
              onChange={e => updateClinicalData('assessment', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Treatment Plan</label>
            <textarea
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              rows={3}
              value={data.clinicalData.plan || ''}
              onChange={e => updateClinicalData('plan', e.target.value)}
            />
          </div>
        </div>
      </div>

      <div className="flex justify-end">
        <button
          type="submit"
          disabled={loading}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
        >
          {loading ? 'Processing...' : 'Generate Report'}
        </button>
      </div>
    </form>
  );
}