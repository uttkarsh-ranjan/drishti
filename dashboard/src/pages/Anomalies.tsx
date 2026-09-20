import React from 'react';

const mockAnomalies = [
  {
    id: 101,
    ngo: 'Bright Future Institute',
    type: 'Proxy Beneficiary Detected',
    score: 0.92,
    time: '10 mins ago',
    shap: [
      { feature: 'L2 Face Distance', impact: 85, color: 'bg-red-500' },
      { feature: 'Facial Landmarks', impact: 15, color: 'bg-orange-400' }
    ]
  },
  {
    id: 102,
    ngo: 'Skill India Hub - Delhi',
    type: 'Crowd Size Discrepancy',
    score: 0.84,
    time: '2 hours ago',
    shap: [
      { feature: 'Density Map Count (20)', impact: 70, color: 'bg-red-500' },
      { feature: 'Reported Attendance (55)', impact: 30, color: 'bg-orange-400' }
    ]
  }
];

const Anomalies = () => {
  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <h2 className="text-3xl font-bold text-slate-800 mb-2">AI Risk Alerts</h2>
      <p className="text-slate-500 mb-8">Review anomalies flagged by the PyTorch/dlib async pipeline.</p>

      <div className="space-y-6">
        {mockAnomalies.map((alert) => (
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
                <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm font-medium">Verify & Assign Corrective Action</button>
                <button className="px-4 py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 rounded text-sm font-medium">Mark as False Positive</button>
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
