# User Roles & System Workflow

## 1. User Types and Access Levels

The Drishti platform employs a Role-Based Access Control (RBAC) model to ensure users only access the data and features relevant to their responsibilities.

### 1.1. DoSJE / Department Officials
* **Primary Interface:** React Web Dashboard
* **Responsibilities:**
  * Global oversight of all registered NGOs and ongoing schemes.
  * Monitor real-time CCTV feeds across all institutions.
  * Initiate and conduct surprise Virtual Audits (Video Conferencing) with facility staff.
  * Review AI-generated anomaly alerts (with SHAP explanations).
  * Enforce compliance by assigning corrective actions and deadlines to NGOs.
* **Access Level:** Global read access, VC initiation rights, write access for corrective actions.

### 1.2. PMU (Project Management Unit) Inspectors
* **Primary Interface:** Flutter Mobile App (Field work) & Web Dashboard (Reporting)
* **Responsibilities:**
  * **On Mobile:** Receive automated, randomised daily inspection assignments via push notifications.
  * Travel to the assigned NGO and bypass the geo-fence verification (must be ≤ 200m).
  * Complete digital offline-first checklists and capture hardware-locked, timestamped evidence (photos/videos).
  * **On Web:** View their historical inspection logs, performance metrics, and upcoming schedules.
* **Access Level:** Restricted read/write access. Can only view and submit data for their daily assigned NGOs.

### 1.3. NGO / Institute Administrators
* **Primary Interface:** React Web Dashboard (Compliance Portal)
* **Responsibilities:**
  * Register the institution, update beneficiary rolls, and submit periodic compliance documents.
  * Register and maintain the RTSP URLs for the institution's CCTV cameras.
  * Accept or decline requests for Virtual Audits (VC).
  * Review and respond to corrective actions assigned by DoSJE Officials.
* **Access Level:** Write access limited strictly to their own institution's compliance and configuration data.

### 1.4. Citizens & Beneficiaries (Future Roadmap)
* **Primary Interface:** Web Portal
* **Responsibilities:** 
  * Access a read-only portal to view the status of service delivery.
  * Submit grievances or feedback regarding the institute/NGO.
* **Access Level:** Public read-only access and isolated write access for grievance submission.

---

## 2. End-to-End System Workflow

The system operates in a closed continuous monitoring loop: **Assign → Verify → Inspect → Capture → Analyse → Prioritise → Correct**.

### Step 1: Onboarding and Registration (When: Start of scheme / Ongoing)
* **Who:** NGO Admins
* **Action:** NGO Admins log into the web dashboard to upload required compliance documents and register their CCTV RTSP feed URLs to the central backend. 

### Step 2: Automated Assignment Routing (When: Daily, <6 hours before audit)
* **Who:** Backend Constraint-Satisfaction Engine (AI)
* **Action:** A background job calculates the optimal inspection routes based on inspector workload, distance, and historical audits to prevent collusion.
* **Result:** PMU Inspectors receive a push notification on their mobile app containing their assigned NGO for the day.

### Step 3: Field Inspection & Zero-Trust Capture (When: During the assigned audit window)
* **Who:** PMU Inspectors
* **Action:** The Inspector arrives on-site. The mobile app verifies they are within the 200-meter geo-fence. 
* **Result:** The Inspector fills out the digital checklist and takes photos. The app hashes the data and timestamps it, blocking any uploads from the gallery, ensuring 100% authentic evidence. If the internet is down, data caches offline and auto-syncs later.

### Step 4: Live Surveillance & Virtual Audits (When: Ad-hoc / Anytime)
* **Who:** DoSJE Officials & NGO Admins
* **Action:** While the physical inspection is happening (or randomly on any day), DoSJE officials log into the dashboard to view sub-500ms latency live CCTV feeds. They can click a button to initiate a surprise Video Call with the NGO staff to verify presence.

### Step 5: Asynchronous AI Analytics (When: Immediately following Step 3)
* **Who:** AI Analytics Engine (Celery Workers)
* **Action:** As soon as the Inspector's evidence hits the backend, AI models analyze the photos to estimate crowd volume and detect proxy beneficiaries.
* **Result:** Risk scores are generated. If a discrepancy is found (e.g. 50 people claimed, but AI counts 20), an anomaly alert is triggered.

### Step 6: Review and Corrective Action (When: Following an anomaly alert)
* **Who:** DoSJE Officials
* **Action:** Officials review the AI alerts on the dashboard. They read the AI's "SHAP explanation" to understand why it was flagged. 
* **Result:** The official validates the alert and creates a corrective action task with a deadline. The NGO Admin is notified and must fix the compliance issue within the platform, closing the accountability loop.
