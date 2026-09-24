# Implementation Plan

## Backend (Agent 1)
1. Add new NGOs with coordinates:
   - NGO 1: 23.793067, 92.727786
   - NGO 2: 23.748473, 92.720840
   - NGO 3: 23.7519177223219, 92.72739487729815
2. Create 3 NGO staff users in DB (one for each NGO) with Role `NGO_Admin`.
3. Create API `POST /api/ngos` to allow DoSJE officials to add NGOs.
4. Create API `GET /api/assignments/current` to fetch the currently assigned NGO for an inspector.
5. Create API `GET /api/evidence/history` to fetch the evidence history for an inspector.
6. Create API `POST /api/users/profile` to handle password change and profile updates.
7. Integrate the laptop webcam stream into MediaMTX via FFMPEG. Run a background script that publishes the laptop camera to MediaMTX on paths `/ngo_1`, `/ngo_2`, `/ngo_3` using RTSP so the dashboard can view them.

## Dashboard (Agent 2)
1. Add "Add NGO" button and modal on the dashboard (visible only to DoSJE_Official).
2. Add Profile page (change password, basic details, disabled 'forgot password' button).
3. Connect the "Live Command Centre" CCTV grid to the actual MediaMTX WebRTC streams (e.g. `http://localhost:8889/ngo_1/`).
4. Update Sidebar with Profile and Add NGO links.

## Mobile App (Agent 3)
1. Refactor Inspection Flow:
   - Screen 1: Dashboard (Shows assigned NGO or "No assignments yet").
   - Screen 2: Location Verification (Button to start GPS check).
   - Screen 3: Camera Capture (Only accessible after GPS check).
2. Add "History" tab to view past captured evidence.
3. Add "Profile" screen (Change password, Logout, disabled Forgot Password).
4. For NGO Staff users: When they login, they should see a "Receive Video Call" screen that connects them to the LiveKit room.
