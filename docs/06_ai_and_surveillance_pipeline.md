# AI and Surveillance Pipeline

## 1. Overview
The Drishti platform utilizes advanced AI and low-latency video streaming to ensure compliance, detect proxy beneficiaries, and provide actionable, explainable risk scores.

## 2. Technology Stack
- **AI Frameworks**: PyTorch, OpenCV, dlib
- **Video Infrastructure**: MediaMTX, LiveKit (WebRTC)

## 3. Implementation Plan

### 3.1. RTSP to WebRTC Live Surveillance (Module C)
- NGOs register RTSP URLs of their institutional CCTV cameras.
- **MediaMTX** is deployed as a multiplexer. It ingests these RTSP feeds and transcodes/muxes them into WHIP/WebRTC formats.
- **Latency Target**: The pipeline is optimized for sub-500ms end-to-end latency (measured at ~412ms at 720p/30fps).
- This allows DoSJE officials to view near real-time ground realities without browser plugins via the React dashboard.

### 3.2. Surprise Video Conferencing
- Integrated using **LiveKit**.
- Allows officials to trigger on-demand, peer-to-peer VC sessions with the facility to perform surprise attendance checks or visual audits.
- Secured using per-room DTLS keys that self-destruct upon disconnect.

### 3.3. AI Anomaly Detection Pipeline (Module D)
The AI pipeline runs asynchronously via Celery to process evidence submitted by inspectors.

#### A. Crowd & Attendance Estimation
- **Model**: MobileNetV3-Small backbone, fine-tuned on the ShanghaiTech dataset.
- **Process**: Takes an image of a classroom/facility and outputs a density map to estimate the crowd volume.
- **Trigger**: An alert is raised if the absolute difference between the estimated crowd and the reported attendance exceeds 25%.

#### B. Proxy Beneficiary Detection
- **Model**: `dlib` ResNet descriptor.
- **Process**: Extracts faces from inspection photos and encodes them into 128-dimensional embeddings.
- **Trigger**: Compares embeddings against historical profiles. If a match is found (L2 distance < 0.45) but the claimed identity is different, a "HIGH-RISK" proxy alert is triggered.

#### C. Explainable Risk Score
- **Model**: A two-layer feed-forward neural network.
- **Inputs (12-feature vector)**: Attendance discrepancy ratio, proxy count, geo-fence violation flag, inspector recency, checklist completion rate, document expiry, historical anomaly frequency, VC refusal count, and 4 scheme-specific indicators.
- **Output**: A risk score (R) between 0 and 1.
- **Explainability**: Uses SHAP (SHapley Additive exPlanations) values to surface per-alert explanations. This ensures that the AI is advisory and human review is mandatory before punitive actions, aligning with Responsible AI practices.
