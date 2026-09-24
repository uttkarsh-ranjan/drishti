import React, { useState, useEffect, useRef } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Sidebar = () => {
  const location = useLocation();
  const { logout, role } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setMenuOpen(false);
      }
    };

    if (menuOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    } else {
      document.removeEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [menuOpen]);

  const links = [
    { path: '/', label: '📹 Live Command Centre' },
    { path: '/anomalies', label: '⚠️ AI Risk Alerts' },
    { path: '/inspections', label: '📋 Inspection Logs' }
  ];

  return (
    <div className="w-64 bg-slate-900 text-white min-h-screen p-4 flex flex-col">
      <div className="mb-8 p-2 border-b border-slate-700">
        <h1 className="text-2xl font-bold text-blue-400">Drishti</h1>
        <p className="text-xs text-slate-400">DoSJE Monitoring Platform</p>
      </div>

      <nav className="flex-1">
        <ul className="space-y-2">
          {links.map((link) => (
            <li key={link.path}>
              <Link
                to={link.path}
                className={`block px-4 py-3 rounded-md transition-colors ${
                  location.pathname === link.path
                    ? 'bg-blue-600 text-white'
                    : 'text-slate-300 hover:bg-slate-800'
                }`}
              >
                {link.label}
              </Link>
            </li>
          ))}
        </ul>
      </nav>

      <div className="mt-auto relative" ref={dropdownRef}>
        {/* Dropdown Menu */}
        {menuOpen && (
          <div className="absolute bottom-full left-0 w-full mb-2 bg-slate-700 rounded-md shadow-lg overflow-hidden border border-slate-600">
            <Link 
              to="/profile" 
              onClick={() => setMenuOpen(false)}
              className="block w-full text-left px-4 py-2 text-sm text-white hover:bg-slate-600 transition-colors"
            >
              Change Password
            </Link>
            <button
              onClick={logout}
              className="block w-full text-left px-4 py-2 text-sm text-red-400 hover:bg-slate-600 transition-colors"
            >
              Sign Out
            </button>
          </div>
        )}
        
        <div 
          className="p-4 bg-slate-800 rounded-md cursor-pointer hover:bg-slate-700 transition-colors"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          <p className="text-sm font-semibold">👤 Profile</p>
          <p className="text-xs text-blue-300">{role ?? 'DoSJE Official'} {menuOpen ? '▴' : '▾'}</p>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
