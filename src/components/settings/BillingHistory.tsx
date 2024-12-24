import React from 'react';
import { Card } from '../ui/card';
import { Download } from 'lucide-react';

export function BillingHistory() {
  const invoices = [
    {
      id: 'INV-2024-001',
      date: '2024-03-01',
      amount: 49.00,
      status: 'Paid',
      downloadUrl: '#'
    },
    {
      id: 'INV-2024-002',
      date: '2024-02-01',
      amount: 49.00,
      status: 'Paid',
      downloadUrl: '#'
    }
  ];

  return (
    <Card className="p-6 bg-white">
      <h2 className="text-xl font-medium text-gray-900 mb-6">Billing History</h2>
      
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200">
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500">Invoice ID</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500">Date</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500">Amount</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-gray-500">Status</th>
              <th className="text-right py-3 px-4 text-sm font-medium text-gray-500">Download</th>
            </tr>
          </thead>
          <tbody className="text-gray-700">
            {invoices.map((invoice) => (
              <tr key={invoice.id} className="border-b border-gray-100 last:border-0">
                <td className="py-4 px-4">{invoice.id}</td>
                <td className="py-4 px-4">{new Date(invoice.date).toLocaleDateString()}</td>
                <td className="py-4 px-4">${invoice.amount.toFixed(2)}</td>
                <td className="py-4 px-4">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    {invoice.status}
                  </span>
                </td>
                <td className="py-4 px-4 text-right">
                  <button 
                    onClick={() => window.open(invoice.downloadUrl, '_blank')}
                    className="text-[#1d7f84] hover:text-[#1d7f84]/80"
                  >
                    <Download className="w-4 h-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}