import React, { useEffect, useState } from 'react';
import { LiveKitRoom, VideoConference, RoomAudioRenderer } from '@livekit/components-react';
import '@livekit/components-styles';
import axios from 'axios';

const LIVEKIT_SERVER_URL = 'wss://livekit.drishti.gov.in';

const CommandCentre = () => {
  const [liveKitToken, setLiveKitToken] = useState<string | null>(null);
  const [tokenError, setTokenError] = useState('');
  const [joinVC, setJoinVC] = useState(false);

  useEffect(() => {
    const apiBase = `http://${window.location.hostname}:5000`;
    axios.get(`${apiBase}/api/livekit/token?room=command_centre`)
      .then(res => setLiveKitToken(res.data.token))
      .catch(() => setTokenError('Could not fetch LiveKit token. Ensure you are logged in and the backend is running.'));
  }, []);

  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-3xl font-bold text-slate-800">Live Command Centre</h2>
          <p className="text-slate-500">Real-time WebRTC multiplexed RTSP feeds via MediaMTX (sub-500ms latency)</p>
        </div>
        <button
          onClick={() => setJoinVC(!joinVC)}
          className="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded shadow"
        >
          {joinVC ? 'Leave VC' : 'Initiate Surprise VC'}
        </button>
      </div>

      {tokenError && (
        <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded text-yellow-700 text-sm">
          ⚠️ {tokenError}
        </div>
      )}

      {/* Surprise VC Room */}
      {joinVC && liveKitToken && (
        <div className="mb-8 bg-black rounded-lg overflow-hidden shadow-lg" style={{ height: '400px' }}>
          <LiveKitRoom serverUrl={LIVEKIT_SERVER_URL} token={liveKitToken} connect={true}>
            <VideoConference />
            <RoomAudioRenderer />
          </LiveKitRoom>
        </div>
      )}

      {/* CCTV Grid (MediaMTX Streams) */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {[1, 2, 3].map((feed) => (
          <div key={feed} className="bg-black rounded-lg overflow-hidden shadow-lg aspect-video relative">
            <iframe 
              src={`http://localhost:8889/ngo_${feed}/`} 
              className="absolute inset-0 w-full h-full border-0"
              title={`MediaMTX Stream NGO ${feed}`}
            />
            <div className="absolute top-2 left-2 pointer-events-none">
              <p className="text-xs text-green-500 font-bold bg-black/60 px-2 py-1 rounded shadow">
                ● LIVE | NGO {feed}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default CommandCentre;
