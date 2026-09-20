# Mobile Application Design & Implementation

## 1. Overview
The mobile app is the primary data collection tool for PMU inspectors. It ensures zero-trust reporting by cryptographically blocking falsified evidence and spoofed locations. 

## 2. Technology Stack
- **Framework**: Flutter
- **Language**: Dart
- **Target Platforms**: Android and iOS
- **Push Notifications**: Firebase Cloud Messaging (FCM)

## 3. Core Features & Implementation Plan

### 3.1. Zero-Trust Geo-Tagged Evidence
To prevent evidence falsification (like submitting pre-captured photos from a gallery), the app implements a zero-trust model:
- **Hardware-Locked Camera**: The app intercepts the native camera API directly. Uploads from the device gallery are cryptographically blocked.
- **On-Device Hashing**: Before upload, the app generates a SHA-256 hash of the raw media payload to prevent in-transit tampering.
- **EXIF Timestamping**: The app attaches an exact timestamp to the evidence. The backend rejects submissions whose EXIF timestamp deviates more than 30 seconds from server-UTC.

### 3.2. Location Verification (Haversine Geo-fence)
To prevent GPS spoofing:
- The app captures direct, network-verified GPS coordinates.
- It calculates proximity to the assigned NGO/Institute's registered coordinates.
- The backend enforces a Haversine geo-fence rule: submissions outside a 200-meter radius of the registered facility are automatically rejected (HTTP 403 Forbidden).

### 3.3. Offline-First Field Workflow
Recognizing that rural institutes might have low connectivity:
- The app implements an offline-first architecture.
- Digital inspection checklists and encrypted evidence are temporarily cached securely on the device if the network drops.
- An auto-sync service runs in the background and uploads the cached data once connectivity is restored.

### 3.4. Inspection Assignments
- Inspectors receive automated assignments through FCM push notifications just 2-6 hours prior to the inspection window.
- The app displays a "Daily Assignment" dashboard detailing the NGO, location, and the specific checklist to complete.

## 4. Integration with Backend
- **Authentication**: JWT tokens stored securely on the device.
- **API Communication**: The app interacts with the Flask API Gateway over TLS 1.3 to submit multipart form data (evidence + metadata).
- **Error Handling**: The app handles HTTP 403 (Geofence/Timestamp failure) gracefully, providing immediate feedback to the inspector.
