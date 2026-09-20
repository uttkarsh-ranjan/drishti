# System Architecture and Integration Plan

## 1. Overview
Drishti follows a closed monitoring loop: **Assign → Verify → Inspect → Capture → Analyse → Prioritise → Correct**. 
The system is built on a 5-tier architecture ensuring zero-trust evidence collection, AI-driven randomised duty assignments, and real-time live surveillance.

## 2. 5-Tier Architecture
The architecture comprises the following tiers:
1. **Mobile Field App**: Used by inspectors for geo-fenced, hardware-locked data collection.
2. **API Gateway**: A central RESTful gateway handling incoming requests, authenticating users, and routing to appropriate microservices.
3. **Microservices Layer**:
   - **Assignment Engine**: Calculates and assigns random inspections.
   - **Evidence Service**: Validates and stores immutable evidence.
   - **AI Analytics**: Asynchronous queue processing for crowd estimation, proxy detection, and risk scoring.
4. **Data Layer**: Relational and spatial data storage.
5. **Dashboard**: Web interface for officials to monitor live feeds, view anomalies, and enforce corrective actions.

## 3. Technology Stack Overview
| Tier | Technology | Purpose |
|------|------------|---------|
| **Mobile** | Flutter (Dart) | Native Android/iOS app; hardware-locked camera & GPS |
| **Dashboard** | React.js + TypeScript | Async WebRTC multi-feed command centre |
| **API** | Python 3.10 + Flask | REST gateway, JWT-RBAC, Celery orchestration |
| **Database** | PostgreSQL 15 + PostGIS | Relational data + spatial geofence queries |
| **AI Engine** | PyTorch, OpenCV, dlib | Anomaly detection, face encoding, crowd estimation |
| **Video** | MediaMTX + LiveKit | RTSP → WebRTC conversion; peer-to-peer Video Conferencing |
| **Security** | TLS 1.3, AES-256, JWT | Transit and at-rest encryption; Role-Based Access Control |

## 4. Integration Flow
1. **Data Collection & Registration**: NGOs and institutes register their details, compliance documents, and RTSP camera URLs in the central backend.
2. **Field Inspection Workflow**:
   - The Assignment Engine (Weighted CSP) runs daily as a background job and selects an inspector for an NGO.
   - The inspector receives the assignment via FCM (Firebase Cloud Messaging) push notifications <6 hours before the audit.
   - The inspector uses the Flutter app to pass the GPS geo-fence check, complete the checklist, and capture hardware-locked evidence.
3. **Evidence Ingestion**: 
   - The Flutter app sends the data to the API Gateway.
   - The API Gateway verifies the SHA-256 hash, EXIF timestamp (within ±30s of server UTC), and uses PostGIS to enforce a Haversine geofence (≤ 200m).
   - Valid data is persisted to PostgreSQL and the Object Store.
4. **AI Processing**:
   - The API Gateway queues tasks in Redis.
   - Celery workers pick up the tasks asynchronously to run AI models (crowd estimation, proxy detection, explainable risk scoring).
5. **Live Surveillance & VC**:
   - MediaMTX multiplexes the registered institutional RTSP feeds and converts them to WebRTC (sub-500ms latency).
   - LiveKit brokers surprise Virtual Audits (Video Conferencing) with per-room DTLS keys.
6. **Dashboard Feedback**: 
   - The React Dashboard fetches aggregated risk scores, anomalies, and evidence from the API.
   - DoSJE officials review SHAP-explained AI alerts and assign corrective actions.

## 5. Security & Deployment
- **RBAC**: Scoped roles via JWT. DoSJE officials have global read and VC initiation rights. PMU inspectors only see daily assigned NGOs. NGO admins have write access for compliance documents.
- **Encryption**: TLS 1.3 (ECDHE) for all API traffic, AES-256-GCM for evidence at rest.
- **Deployment**: The backend components (Flask, PostgreSQL, MediaMTX, Celery) are containerised using Docker and orchestrated via Docker Compose. Auto-scaling is managed based on Celery queue depths.
