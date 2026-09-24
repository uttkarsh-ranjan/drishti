import React, { useState } from 'react';
import axios from 'axios';

const AddNgo = () => {
  const [name, setName] = useState('');
  const [lat, setLat] = useState('');
  const [lng, setLng] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const handleAddNgo = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage('');
    setError('');
    try {
      const apiBase = `http://${window.location.hostname}:5000`;
      await axios.post(`${apiBase}/api/ngos`, {
        name,
        latitude: parseFloat(lat),
        longitude: parseFloat(lng)
      });
      setMessage('NGO added successfully.');
      setName('');
      setLat('');
      setLng('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to add NGO.');
    }
  };

  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <h2 className="text-3xl font-bold text-slate-800 mb-6">Add NGO</h2>
      <div className="bg-white p-6 rounded shadow-md max-w-md">
        <form onSubmit={handleAddNgo}>
          {message && <div className="mb-4 p-2 bg-green-50 text-green-700 text-sm rounded">{message}</div>}
          {error && <div className="mb-4 p-2 bg-red-50 text-red-700 text-sm rounded">{error}</div>}
          
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-700 mb-1">NGO Name</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-700 mb-1">Latitude</label>
            <input
              type="number"
              step="any"
              value={lat}
              onChange={e => setLat(e.target.value)}
              className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div className="mb-6">
            <label className="block text-sm font-medium text-slate-700 mb-1">Longitude</label>
            <input
              type="number"
              step="any"
              value={lng}
              onChange={e => setLng(e.target.value)}
              className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          
          <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded transition-colors">
            Add NGO
          </button>
        </form>
      </div>
    </div>
  );
};

export default AddNgo;
