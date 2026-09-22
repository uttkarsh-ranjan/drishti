import React, { useEffect, useState } from 'react';
import axios from 'axios';

interface Inspection {
  id: number;
  ngo_name: string;
  inspector_name: string;
  timestamp: string;
  status: string;
  evidence_hash: string;
}

const Inspections = () => {
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Mock data for now
    setInspections([
      {
        id: 1,
        ngo_name: "Hope Foundation",
        inspector_name: "Jane Doe",
        timestamp: new Date().toISOString(),
        status: "Verified",
        evidence_hash: "a3b9c8d7e6f5"
      },
      {
        id: 2,
        ngo_name: "Care India",
        inspector_name: "John Smith",
        timestamp: new Date().toISOString(),
        status: "Pending",
        evidence_hash: "f5e6d7c8b9a3"
      }
    ]);
    setLoading(false);
  }, []);

  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-3xl font-bold text-slate-800">Inspection Logs</h2>
          <p className="text-slate-500">Immutable audit trail of all geo-tagged evidence.</p>
        </div>
        <button 
          onClick={() => {
            const csv = ['ID,NGO Name,Inspector,Timestamp,Status,Evidence Hash'];
            inspections.forEach(i => {
              csv.push(`${i.id},"${i.ngo_name}","${i.inspector_name}",${i.timestamp},${i.status},${i.evidence_hash}`);
            });
            const blob = new Blob([csv.join('\n')], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'inspection_logs.csv';
            a.click();
            window.URL.revokeObjectURL(url);
          }}
          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded shadow"
        >
          Export Report
        </button>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden border border-slate-200">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">NGO Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Inspector</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Timestamp</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Evidence Hash</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-slate-200">
            {inspections.map((inspection) => (
              <tr key={inspection.id} className="hover:bg-slate-50">
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900">#{inspection.id}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{inspection.ngo_name}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{inspection.inspector_name}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">{new Date(inspection.timestamp).toLocaleString()}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    inspection.status === 'Verified' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                  }`}>
                    {inspection.status}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500 font-mono">
                  {inspection.evidence_hash}...
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Inspections;
