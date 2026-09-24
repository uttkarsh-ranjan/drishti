import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Sidebar from './components/Sidebar';
import CommandCentre from './pages/CommandCentre';
import Anomalies from './pages/Anomalies';
import Inspections from './pages/Inspections';
import Login from './pages/Login';
import Profile from './pages/Profile';
import AddNgo from './pages/AddNgo';

const ProtectedLayout = () => {
  const { token, role } = useAuth();
  if (!token) return <Navigate to="/login" replace />;
  return (
    <div className="flex min-h-screen bg-slate-100 font-sans">
      <Sidebar />
      <main className="flex-1 overflow-x-hidden overflow-y-auto">
        <Routes>
          <Route path="/" element={<CommandCentre />} />
          <Route path="/anomalies" element={<Anomalies />} />
          <Route path="/inspections" element={<Inspections />} />
          <Route path="/profile" element={<Profile />} />
          {role === 'DoSJE_Official' && <Route path="/add-ngo" element={<AddNgo />} />}
        </Routes>
      </main>
    </div>
  );
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/*" element={<ProtectedLayout />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
