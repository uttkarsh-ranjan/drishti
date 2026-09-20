import React from 'react';
import { LiveKitRoom, VideoConference, RoomAudioRenderer } from '@livekit/components-react';
import '@livekit/components-styles';

const CommandCentre = () => {
  // In a real app, these would be fetched dynamically from the Flask API for the selected NGO
  const serverUrl = 'wss://livekit.drishti.gov.in'; 
  const token = 'placeholder_token_for_mock'; 
  const isMock = true; // Set to false to actually attempt connection

  return (
    <div className="flex-1 p-8 bg-slate-50 min-h-screen">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-3xl font-bold text-slate-800">Live Command Centre</h2>
          <p className="text-slate-500">Real-time WebRTC multiplexed RTSP feeds (sub-500ms latency)</p>
        </div>
        <button className="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded shadow">
          Initiate Surprise VC
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {/* Mocking Multiple CCTV Streams */}
        {[1, 2, 3, 4, 5, 6].map((feed) => (
          <div key={feed} className="bg-black rounded-lg overflow-hidden shadow-lg aspect-video relative">
            
            {/* LiveKit integration placeholder */}
            {!isMock ? (
              <LiveKitRoom
                serverUrl={serverUrl}
                token={token}
                connect={true}
              >
                <VideoConference />
                <RoomAudioRenderer />
              </LiveKitRoom>
            ) : (
              <div className="absolute inset-0 flex flex-col items-center justify-center text-slate-500">
                <span className="text-4xl mb-2">📹</span>
                <p>MediaMTX WebRTC Stream {feed}</p>
                <p className="text-xs text-green-500 mt-2">● LIVE | NGO ID: {1000 + feed}</p>
              </div>
            )}
            
          </div>
        ))}
      </div>
    </div>
  );
};

export default CommandCentre;
