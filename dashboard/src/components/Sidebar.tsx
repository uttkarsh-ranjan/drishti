import { Link, useLocation } from 'react-router-dom';

const Sidebar = () => {
  const location = useLocation();

  const links = [
    { path: '/', label: 'Live Command Centre' },
    { path: '/anomalies', label: 'AI Risk Alerts' },
    { path: '/inspections', label: 'Inspection Logs' },
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

      <div className="mt-auto p-4 bg-slate-800 rounded-md">
        <p className="text-sm font-semibold">Logged in as:</p>
        <p className="text-xs text-blue-300">DoSJE Official</p>
      </div>
    </div>
  );
};

export default Sidebar;
