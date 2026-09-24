import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import axios from 'axios';

const Profile = () => {
  const { logout, role } = useAuth();
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage('');
    setError('');
    try {
      const apiBase = `http://${window.location.hostname}:5000`;
      await axios.post(`${apiBase}/api/users/profile`, { current_password: currentPassword, new_password: newPassword });
      setMessage('Password updated successfully.');
      setCurrentPassword('');
      setNewPassword('');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update password.');
    }
  };

  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <h2 className="text-3xl font-bold text-slate-800 mb-6">Profile</h2>
      <div className="bg-white p-6 rounded shadow-md max-w-md">
        <div className="mb-4">
          <p className="text-sm text-slate-500 font-semibold mb-1">Role</p>
          <p className="text-lg text-slate-800">{role ?? 'Unknown'}</p>
        </div>
        
        <form onSubmit={handleChangePassword} className="mt-6 border-t pt-6 border-slate-200">
          <h3 className="text-xl font-semibold text-slate-800 mb-4">Change Password</h3>
          {message && <div className="mb-4 p-2 bg-green-50 text-green-700 text-sm rounded">{message}</div>}
          {error && <div className="mb-4 p-2 bg-red-50 text-red-700 text-sm rounded">{error}</div>}
          
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-700 mb-1">Current Password</label>
            <input
              type="password"
              value={currentPassword}
              onChange={e => setCurrentPassword(e.target.value)}
              className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-700 mb-1">New Password</label>
            <input
              type="password"
              value={newPassword}
              onChange={e => setNewPassword(e.target.value)}
              className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>
          
          <div className="flex gap-4">
            <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded transition-colors">
              Update Password
            </button>
          </div>
        </form>
        
        <div className="mt-8 border-t pt-6 border-slate-200">
          <button onClick={logout} className="w-full bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-4 rounded transition-colors">
            Log Out
          </button>
        </div>
      </div>
    </div>
  );
};

export default Profile;
