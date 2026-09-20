# Backend API and Microservices Design

## 1. Overview
The backend acts as the orchestrator for the entire Drishti platform. It is split into a central API Gateway and several specialised microservices to handle complex business logic like assignments and AI processing.

## 2. Technology Stack
- **Language**: Python 3.10
- **API Framework**: Flask
- **Task Queue**: Celery
- **Message Broker / Cache**: Redis
- **Security**: JWT for RBAC, TLS 1.3, AES-256 for data at rest.

## 3. Core Services & Implementation Plan

### 3.1. API Gateway (Flask)
- Provides RESTful endpoints for the Flutter App and React Dashboard.
- **Authentication**: Validates JWTs and enforces Role-Based Access Control (RBAC).
- **Evidence Verification**: Implements the zero-trust checks:
  - Validates SHA-256 hashes of incoming media.
  - Compares media EXIF timestamps with server UTC (rejects > 30s diff).
  - Queries PostGIS to execute the Haversine formula (Eq. 1) to verify the inspector is ≤ 200m from the NGO centroid.
- Returns HTTP 403 if validation fails and immutably logs the attempt.

### 3.2. Assignment Engine (Weighted CSP)
- A background job (cron/Celery beat) runs daily to automate inspection routing.
- Implements a Weighted Constraint-Satisfaction Problem (WCSP) algorithm.
- Minimizes a cost function based on:
  - Geodesic distance to the facility.
  - Inspector workload.
  - Penalties for assigning the same inspector within 30 days (reducing collusion).
- Generates assignments and triggers FCM push notifications <6 hours before the audit window to eliminate predictable schedules.

### 3.3. Asynchronous AI Analytics Queue
- When inspection evidence is accepted, the API gateway drops a task into Redis.
- A pool of **Celery workers** picks up these tasks asynchronously to avoid blocking API responses.
- The Celery workers interact with the AI Engine (PyTorch/dlib) to perform crowd estimation and proxy detection.
- Results are saved to the database, and high-risk flags are pushed to the dashboard.
- **Scalability**: The Celery worker pool scales horizontally. Auto-scaling is managed via metrics like queue depth.

### 3.4. Video & Surveillance Integration
- **MediaMTX**: Run as a separate Docker container. It ingests institutional RTSP feeds and multiplexes them into WebRTC for the React dashboard.
- **LiveKit**: Brokers the surprise VC sessions. The Flask API generates secure tokens for clients to join LiveKit rooms on-demand.

## 5. Deployment
- The entire backend stack (Flask API, Celery Workers, Redis) is containerised using **Docker** and managed via **Docker Compose**.
- Designed to be deployed on cloud infrastructure (e.g., AWS ECS Fargate, NIC Cloud / MeghRaj) with load balancers terminating TLS.
