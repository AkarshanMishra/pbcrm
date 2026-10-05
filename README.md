# PCRM — Advanced Secure Employee Management System (Phase 1)

Production-ready enterprise employee management platform featuring **Zero-Trust Authentication**, **Role & Position Based Access Control (RBAC)**, **Tamper-Proof Attendance**, **Append-Only Security Audit Trail**, **Device & Session Management**, and a **Modern Flutter Mobile Client**.

---

## 🏛️ System Architecture

```text
                    MOBILE APP (Flutter)
                             │
                     HTTPS / TLS 1.3
                             │
                             ▼
                    NGINX REVERSE PROXY
                             │
                             ▼
                  DJANGO REST FRAMEWORK API
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
    Authentication     Authorization      Business Logic
     (JWT + MFA)       (RBAC Matrix)      (Attendance/Dept)
          │                  │                  │
          └──────────────────┼──────────────────┘
                             ▼
                    PostgreSQL 16 + Redis 7
                             │
             ┌───────────────┼───────────────┐
             ▼               ▼               ▼
        Audit Logs       Sessions         Backups
       (Append-Only)  (Device Bound)    (Encrypted)
```

---

## 🚀 Key Features Implemented

### 1. Zero-Trust Authentication & Identity Defense
* **Login Identifier**: Dual support for Employee ID (`PBE000001`) or Email.
* **MFA Verification**: TOTP Authenticator Apps (Google Authenticator, Authy) + 8 single-use cryptographically hashed Emergency Recovery Codes (Mandatory for Administrators).
* **Password Policy Enforcement**: Argon2/PBKDF2 hashing, 12+ character complexity validator, ZXCVBN entropy validation, and 5-cycle password history restriction.
* **Brute-Force & Lockout**: Automatic 15-minute exponential account lockout upon 5 consecutive failed login attempts.
* **Session & Token Rotation**: 15-minute short-lived JWTs with refresh token rotation, device fingerprinting, and remote session revocation ("Log Out Other Devices").

### 2. Hierarchical RBAC & Dynamic Permission Matrix
* **Structure**: `Department` $\rightarrow$ `Position` $\rightarrow$ `Role` $\rightarrow$ `Permissions`.
* **Roles Included**: `ADMIN`, `IT`, `MARKETING`, `OPERATIONS`, `ACCOUNTS`.
* **Object-Level Boundaries**: Employees access only self-records; Managers access direct team reports; Administrators manage organization-wide operations.

### 3. Tamper-Proof Attendance Module
* **Authoritative Server Timestamps**: Check-in and check-out times generated strictly on the server (client device clock spoofing prevented).
* **Duplicate Prevention**: Database composite unique constraint on `(employee, attendance_date)`.
* **Correction Workflow**: Formal request-review workflow with Manager/Admin approval and complete audit trail.

### 4. Append-Only Audit Trail & Security Center
* **Audit Logger**: Captures `actor`, `event_type`, `target`, `ip_address`, `user_agent`, and `diff metadata`.
* **Security Operations Center**: Live tracking of failed logins, locked accounts, active sessions, and new devices.

---

## 🛠️ Quickstart Guide

### Prerequisites
* Python 3.12+
* Docker & Docker Compose (for containerized deployment)
* Flutter 3.2+ (for mobile app)

---

### Local Backend Setup

1. **Activate Virtual Environment**:
   ```powershell
   cd backend
   .\venv\Scripts\Activate.ps1
   ```

2. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Apply Database Migrations**:
   ```bash
   python manage.py migrate
   ```

4. **Seed Phase 1 Baseline Data**:
   ```bash
   python manage.py seed_phase1_data
   ```

   **Default Seeded Credentials:**
   * **Admin**: `PBE000001` (`admin@pcrm.local`) / Password: `AdminPassword@123!`
   * **Manager**: `PBE000002` (`it.manager@pcrm.local`) / Password: `ManagerPassword@123!`
   * **Employee**: `PBE000003` (`dev.rahul@pcrm.local`) / Password: `EmployeePassword@123!`

5. **Run the Backend API Server**:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
   * **Interactive Swagger UI**: `http://localhost:8000/api/docs/`
   * **Redoc Specification**: `http://localhost:8000/api/redoc/`

---

### Running Automated Test Suite

Execute the test suite covering authentication, MFA, password complexity, attendance duplicate prevention, employee provisioning, and audit logs:

```bash
pytest backend/tests
```

---

### Docker Deployment

Run the complete multi-container stack (PostgreSQL 16, Redis 7, Django API, Nginx Reverse Proxy):

```bash
docker-compose up --build -d
```

---

### Mobile Application (Flutter)

1. **Navigate to Mobile App Directory**:
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Run Mobile App**:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
pcrm/
├── backend/
│   ├── apps/
│   │   ├── core/                    # UUID models, pagination, custom exceptions
│   │   ├── accounts/                # Custom User, MFA/TOTP, Devices, Sessions, Password policy
│   │   ├── organization/            # Departments, Positions, Roles, Permissions matrix
│   │   ├── employees/               # Employee Profiles, PBE sequence generator, status lifecycle
│   │   ├── attendance/              # Server timestamps, Check-in/out, Correction workflow
│   │   ├── audit/                   # Append-only audit logger and middleware
│   │   └── security_center/         # SOC Metrics and Account unlock endpoints
│   ├── config/                      # Settings (base, development, production), URLs, WSGI, ASGI
│   ├── tests/                       # Pytest test suite
│   ├── requirements.txt
│   └── manage.py
├── mobile/
│   ├── lib/
│   │   ├── core/                    # Dio client with JWT refresh rotation, secure storage, theme
│   │   ├── models/                  # AuthUser, AttendanceRecord DTOs
│   │   ├── providers/               # Auth & Attendance state management
│   │   └── screens/
│   │       ├── auth/                # Login, MFA challenge
│   │       ├── employee/            # Employee Dashboard & Punch card
│   │       ├── attendance/          # Attendance history & Correction requests
│   │       ├── security/            # Registered Devices & Session revocation
│   │       └── admin/               # SOC Dashboard & Employee directory
│   └── pubspec.yaml
├── docker/
│   ├── Dockerfile.django
│   └── nginx.conf
├── docker-compose.yml
├── .env.example
└── README.md
```
