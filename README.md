# AI Assisted Smart Dairy Application

> **Offline-First, AI-Assisted Mobile & Cloud Solution for Rural Milk Collection, Real-Time Billing & Cooperative Informatics**  
> Developed for small-scale dairy cooperatives, dairy owners, and milk suppliers (farmers).

---

## 1. Project Architecture

```
┌─────────────────────────────────┐        REST / HTTPS        ┌──────────────────────────────────┐        TLS / TCP        ┌─────────────────────────────────┐
│     Flutter Android Client      │ ─────────────────────────> │    Spring Boot 3.4.3 Backend     │ ──────────────────────> │       MongoDB Atlas Cloud       │
│   (Dart 3.13 / Material 3)      │ <───────────────────────── │     (Java 23 / Stateless JWT)    │ <────────────────────── │         (AWS Mumbai M0)         │
└─────────────────────────────────┘                            └─────────────────┬────────────────┘                         └─────────────────────────────────┘
                                                                                 │
                                                  ┌──────────────────────────────┼──────────────────────────────┐
                                                  ▼                              ▼                              ▼
                                     ┌─────────────────────────┐   ┌───────────────────────────┐  ┌───────────────────────────┐
                                     │      AI Engine / LLM    │   │      SMS / Fast2SMS       │  │     Route / Maps API      │
                                     │  (Llama 3.1 / Ollama /  │   │  (Instant Shift Receipts  │  │  (Tanker Transit Duration │
                                     │   Groq Cloud API)       │   │   & Settlement Notices)   │  │   & Distance Matrix)      │
                                     └─────────────────────────┘   └───────────────────────────┘  └───────────────────────────┘
```

---

## 2. Technology Stack

- **Frontend Mobile App**:
  - Flutter 3.47.x, Dart 3.13.x
  - Material 3 Design with Dark / Light Theme & Dual-Language Support (English / मराठी)
  - Bluetooth Low Energy (BLE) integration for digital scales & ultrasonic milk analyzers
  - Local sync queue with offline-first fail-safe operation
- **Backend REST API**:
  - Spring Boot 3.4.3 with Java 23
  - Spring Security with Stateless JSON Web Token (JWT) & BCrypt Encryption
  - Role-Based Access Control (`DAIRY_OWNER`, `MEMBER`, `EMPLOYEE`, `ADMIN`)
- **Database**:
  - MongoDB Atlas Cloud (Shared cluster, multi-region failover)
  - Automatic collection index creation and schema-safe documents
- **AI & Analytics**:
  - Conversational AI Assistant powered by Meta **Llama 3.1** via Groq Cloud API & local Ollama
  - Built-in rule-based knowledge fallback covering animal husbandry, dairy science, and feed management
  - Machine learning anomaly detection & milk quality classification

---

## 3. Core Features & Capabilities

1. **Role-Based Access Control**:
   - **Dairy Owner**: Complete management of milk collection shifts (Morning/Evening), member registry, rate charts, advances, and 10-day cycle billing.
   - **Member (Farmer)**: Private digital passbook showing daily delivery slips, FAT/SNF readings, rate calculations, cycle payout statements, and pending advances.
   - **Admin**: Audit logs, security inspection, and system metrics.

2. **Dual-Axis FAT & SNF Pricing**:
   - Dynamic formula: $\text{Rate} = \text{BaseRate} + ((\text{FAT} - \text{MinFAT}) \times 10 \times \text{Step}) + ((\text{SNF} - \text{MinSNF}) \times 10 \times \text{Step})$.
   - Pre-configured rate rules for **Cow** (Base ₹38.0/L) and **Buffalo** (Base ₹54.0/L).

3. **10-Day Cooperative Billing Cycles**:
   - Cycle 1 (Days 1–10), Cycle 2 (Days 11–20), Cycle 3 (Days 21–End of Month).
   - Certified PDF detailed statements, shift slips, and payout receipts.

4. **Multi-Channel External Services**:
   - Automated bilingual SMS receipts to farmers after every milk entry.
   - Route and transit time optimization for milk tankers to chilling centers.

---

## 4. Project Structure

```text
smart-dairy-app/
├── android/            # Android native project & manifest (uses-permission INTERNET)
├── backend/            # Spring Boot 3.4.3 (Java 23) microservice
│   ├── src/main/java/  # Controllers, Services, Entities, Repositories, Security
│   ├── src/main/resources/application.yml  # Cloud-ready configuration
│   ├── Dockerfile      # Multi-stage Eclipse Temurin Java 23 container
│   └── build.gradle    # Gradle build dependencies
├── lib/                # Flutter application source code
│   ├── dashboard/      # Owner & Member interactive dashboards
│   ├── milk_collection/# Shift collection screen & BLE auto-read
│   ├── screens/        # AI Chatbot, Account registration, Audit history
│   ├── services/       # ApiService, SyncService, PdfGeneratorService
│   └── main.dart       # Application entry point & theme configuration
└── README.md
```

---

## 5. Cloud Deployment Guide

### A. Database (MongoDB Atlas)
1. Configure `SPRING_DATA_MONGODB_URI` environment variable with your Atlas cluster SRV string.
2. IP Whitelist: Ensure `0.0.0.0/0` is added in Network Access for cloud server connectivity.

### B. Backend (Render / Docker)
1. Connect this GitHub repository on [Render](https://render.com).
2. Set **Root Directory** to `backend`.
3. Select **Docker** runtime (uses `backend/Dockerfile`).
4. Set Environment Variables:
   - `SPRING_DATA_MONGODB_URI`: your MongoDB Atlas connection string.
   - `PORT`: `8080`.
   - `JWT_SECRET`: your 256-bit JWT signing secret.

---

## 6. License & Authors

Developed by **Vishwajeet Gavali** and Team  
Department of Computer Science and Engineering  
D. Y. Patil College of Engineering and Technology, Kolhapur, India.
