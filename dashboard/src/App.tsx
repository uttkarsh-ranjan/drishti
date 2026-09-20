import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import CommandCentre from './pages/CommandCentre';
import Anomalies from './pages/Anomalies';

function App() {
  return (
    <Router>
      <div className="flex min-h-screen bg-slate-100 font-sans">
        <Sidebar />
        <main className="flex-1 overflow-x-hidden overflow-y-auto">
          <Routes>
            <Route path="/" element={<CommandCentre />} />
            <Route path="/anomalies" element={<Anomalies />} />
            <Route path="/inspections" element={
              <div className="p-8">
                <h2 className="text-3xl font-bold mb-4">Inspection Logs</h2>
                <p>Immutable audit trail of all geo-tagged evidence will appear here.</p>
              </div>
            } />
          </Routes>
        </main>
      </div>
    </Router>
  )
}

export default App
