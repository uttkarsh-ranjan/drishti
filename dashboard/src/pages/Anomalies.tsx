import React, { useEffect, useState } from 'react';
import axios from 'axios';

interface ShapFeature {
  feature: string;
  impact: number;
  color: string;
}

interface AnomalyData {
  id: number;
  ngo: string;
  type: string;
  score: number;
  time: string;
  shap: ShapFeature[];
}

const Anomalies = () => {
  const [anomalies, setAnomalies] = useState<AnomalyData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    // Fetch anomalies from Flask API
    const apiBase = `http://${window.location.hostname}:5000`;
    axios.get(`${apiBase}/api/anomalies`)
      .then(response => {
        setAnomalies(response.data);
        setLoading(false);
      })
      .catch(err => {
        console.error("Error fetching anomalies:", err);
        setError('Failed to load AI risk alerts from the server. Ensure the Flask API is running.');
        setLoading(false);
      });
  }, []);

  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <h2 className="text-3xl font-bold text-slate-800 mb-2">AI Risk Alerts</h2>
      <p className="text-slate-500 mb-8">Review anomalies flagged by the PyTorch/dlib async pipeline.</p>

      {loading && <p className="text-slate-500 animate-pulse">Loading alerts from AI Engine...</p>}
      {error && <p className="text-red-500 font-medium">{error}</p>}

      <div className="space-y-6">
        {anomalies.map((alert) => (
          <div key={alert.id} className="bg-white p-6 rounded-lg shadow border-l-4 border-red-500 flex flex-col md:flex-row gap-6">
            
            {/* Alert Summary */}
            <div className="flex-1">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-xl font-bold text-slate-800">{alert.type}</h3>
                <span className="px-3 py-1 bg-red-100 text-red-700 text-sm font-bold rounded-full">
                  Risk: {(alert.score * 100).toFixed(0)}%
                </span>
              </div>
              <p className="text-slate-600 font-medium">{alert.ngo}</p>
              <p className="text-slate-400 text-sm mt-1">{alert.time}</p>
              
              <div className="mt-4 flex gap-3">
                <button 
                  onClick={() => alert(`Action assigned for anomaly #${alert.id}`)}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm font-medium">
                  Verify & Assign Corrective Action
                </button>
                <button 
                  onClick={() => alert(`Anomaly #${alert.id} marked as False Positive`)}
                  className="px-4 py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 rounded text-sm font-medium">
                  Mark as False Positive
                </button>
              </div>
            </div>

            {/* Explainable AI (SHAP) Box */}
            <div className="w-full md:w-1/3 bg-slate-50 p-4 rounded border border-slate-200">
              <h4 className="text-sm font-bold text-slate-700 mb-3 flex items-center gap-2">
                <span>🤖</span> Explainable AI (SHAP)
              </h4>
              <div className="space-y-3">
                {alert.shap.map((f, i) => (
                  <div key={i}>
                    <div className="flex justify-between text-xs text-slate-600 mb-1">
                      <span>{f.feature}</span>
                      <span>{f.impact}% impact</span>
                    </div>
                    <div className="w-full bg-slate-200 rounded-full h-2">
                      <div className={`${f.color} h-2 rounded-full`} style={{ width: `${f.impact}%` }}></div>
                    </div>
                  </div>
                ))}
              </div>
              <p className="text-xs text-slate-400 mt-4 italic">Mandatory human review required before punitive action (DPDPA 2023 Compliant).</p>
            </div>

          </div>
        ))}
      </div>
    </div>
  );
};

export default Anomalies;
