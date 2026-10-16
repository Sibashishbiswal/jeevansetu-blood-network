# 🩸 JeevanSetu: Geo-Fenced Critical Blood Donor Matching & Emergency Dispatch Network

> **Build Something Real – Project Evaluation (20 Marks)**  
> **Student:** 3rd Year Computer Science & Engineering  
> **Institution:** Vivekananda Institute of Professional Studies - Technical Campus (VIPS-TC)

---

## 📌 Executive Summary
**JeevanSetu** is a real-time, geo-fenced emergency blood donation mobile application designed to eliminate critical delays during emergency trauma surgeries, postpartum hemorrhages, and rare blood shortages (e.g., O-negative, AB-negative). 

Traditional broadcast methods (such as unverified WhatsApp/social media forwards) lead to fatal delays, predatory blood brokers, and alert fatigue. JeevanSetu bridges this gap by directly matching verified hospital SOS requests with nearby eligible voluntary donors within an optimized 5–10 km radius using mathematical geospatial proximity (Haversine formula) and clinical compatibility rules—enforcing a strict 90-day medical safety cooldown.

---

## 🎯 Key Objectives
1. **Sub-15s Dispatch Latency:** Match and notify eligible donors within a 5 km radius in under 15 seconds.
2. **Clinical Safety Guarantee:** Built-in blood compatibility matrix (e.g., O- universal donor logic) and enforced 90-day cooldown to prevent donor burnout.
3. **Elimination of Zombie SOS Broadcasts:** Dynamic ticket states that lock down automatically upon donor acceptance to avoid chaotic hospital overcrowding.
4. **100% Free & Open-Source:** Zero API billing surprises; built using **Flutter**, **OpenStreetMap (OSM)**, and **Geolocator**.

---

## 📱 Core Features

### 1. 🗺️ Live OpenStreetMap (OSM) Dispatch Radar
* Interactive free OpenStreetMap rendered via `flutter_map`.
* Visualizes real-time hospital SOS locations with emergency pulsing dispatch radius circles (5 km – 15 km).
* Displays live community donor positions and donor readiness status.

### 2. ⚡ Real-Time Emergency SOS Feed
* Two categorized views: **"Eligible For You"** (filtered strictly by your blood group + 90-day eligibility + distance) and **"All Active SOS"**.
* Dynamic status tracker: `SOS PENDING` ➔ `ACCEPTED` ➔ `EN ROUTE` ➔ `FULFILLED`.

### 3. 🏥 Hospital Emergency Dispatch Desk
* Clean intake form for hospital triage staff to input patient bed, units needed, blood group, and set emergency radius.
* Single-click emergency broadcast to the network.

### 4. 🪪 Donor Profile & Digital Medical Pass
* Displays real-time donor eligibility status with countdown timers.
* Dynamic **Clinical Compatibility Matrix** showing exactly which blood groups the user can donate to and receive from.
* Quick testing mode toggle to simulate different blood groups and roles (Donor View vs. Hospital Authority View) for demonstration purposes.

---

## 🛠️ Technology Stack
* **Frontend / Framework:** [Flutter](https://flutter.dev/) (Dart 3.x, Flutter 3.47+)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Geospatial & Mapping:** 
  * [`flutter_map`](https://pub.dev/packages/flutter_map) (Powered by open-source OpenStreetMap tile servers)
  * [`geolocator`](https://pub.dev/packages/geolocator) (Device GPS positioning & accuracy)
  * [`latlong2`](https://pub.dev/packages/latlong2) (Haversine spherical distance calculations)
* **Typography & UI:** [Google Fonts (Inter)](https://fonts.google.com/specimen/Inter), Material Design 3

---

## 🏗️ System Architecture

```text
       ┌────────────────────────────────────────────────────────┐
       │                Flutter Mobile App                      │
       │                                                        │
       │   [ Live Map (OSM) ]      [ SOS Alert Feed ]           │
       │   [ Hospital Dispatch ]   [ Donor Medical Pass ]       │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                  AppState Engine                       │
       │                                                        │
       │  • Haversine Distance Filter (d <= Radius Km)          │
       │  • BloodMatrix (ABO & Rh Clinical Compatibility)       │
       │  • Medical Cooldown Checker (>= 90 Days)               │
       │  • Concurrency Locking (Avoid Duplicate Acceptances)   │
       └───────────────────────────┬────────────────────────────┘
                                   │
                   ┌───────────────┴───────────────┐
                   ▼                               ▼
       ┌───────────────────────┐       ┌───────────────────────┐
       │   OpenStreetMap API   │       │  Device GPS Hardware  │
       │   (Free Map Tiles)    │       │  (Geolocator Service) │
       └───────────────────────┘       └───────────────────────┘
```

---

## 🚀 How to Run the Project Locally

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (Version 3.47+ recommended)
* Google Chrome or an Android device with USB debugging enabled.

### Step-by-Step Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<your-username>/rakshak-blood-network.git
   cd rakshak-blood-network
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Verify installation:**
   ```bash
   flutter analyze
   ```
   *(Expected output: No issues found!)*

4. **Run the App in Chrome (Instant Testing):**
   ```bash
   flutter run -d chrome
   ```

5. **Run on an Android Phone (Native Mobile Mode):**
   * Connect your Android phone via USB and enable **USB Debugging** in Developer Options.
   * Run:
     ```bash
     flutter run
     ```

6. **Build Release APK for Distribution:**
   ```bash
   flutter build apk --release
   ```
   The generated APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔬 Clinical Blood Compatibility Logic

| Patient Blood Group | Compatible Donor Blood Groups |
|---|---|
| **O-** | **O-** only |
| **O+** | **O-**, **O+** |
| **A-** | **O-**, **A-** |
| **A+** | **O-**, **O+**, **A-**, **A+** |
| **B-** | **O-**, **B-** |
| **B+** | **O-**, **O+**, **B-**, **B+** |
| **AB-**| **O-**, **A-**, **B-**, **AB-** |
| **AB+**| **All 8 Blood Groups** *(Universal Recipient)* |

---

## 📜 License
This project is open-source under the **MIT License** for academic and public healthcare evaluation.
