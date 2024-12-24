import React, { useState, useEffect } from 'react';
import { Building, Plus } from 'lucide-react';
import { organizationService } from '../../lib/organizationService';
import type { Branch } from '../../types/organization.types';
import { BranchForm } from './BranchForm';

export function BranchList() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    loadBranches();
  }, []);

  const loadBranches = async () => {
    try {
      const data = await organizationService.getBranches();
      setBranches(data);
    } catch (error) {
      console.error('Error loading branches:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Facilities</h2>
        <button
          onClick={() => setShowForm(true)}
          className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
        >
          <Plus className="h-4 w-4 mr-2" />
          Add Facility
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {branches.map(branch => (
          <div key={branch.id} className="bg-white rounded-lg shadow p-6">
            <div className="flex items-start">
              <Building className="h-5 w-5 text-gray-400 mr-3" />
              <div>
                <h3 className="text-lg font-medium">{branch.name}</h3>
                <p className="text-sm text-gray-500">{branch.location}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {showForm && (
        <BranchForm
          onClose={() => setShowForm(false)}
          onSave={async () => {
            await loadBranches();
            setShowForm(false);
          }}
        />
      )}
    </div>
  );
}