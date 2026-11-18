# 🩸 JeevanSetu: Geo-Fenced Critical Blood Donor Matching & Emergency Dispatch Network

> **Build Something Real – Project Evaluation (20 Marks)**  
> **Student:** Sibashish Biswal (3rd Year Computer Science & Engineering)  
> **Institution:** Vivekananda Institute of Professional Studies - Technical Campus (VIPS-TC)  
> **Live Web App:** https://sibashishbiswal.github.io/jeevansetu-blood-network/

---

## 🚨 The Problem Today (What Happens in Real Life)
When a person meets with a severe road accident or a mother is bleeding in emergency surgery, the hospital often runs out of blood on their shelves (especially rare groups like **O-negative**).

* **What families do right now:** They panic and forward frantic messages on WhatsApp and Instagram: *"URGENT! Need O- blood at AIIMS! Please forward!"*
* **Why this fails:**
  1. It wastes **2 to 4 hours** while the patient is bleeding to death (the **"Golden Hour"**).
  2. People receiving the forward might be **50 km away** or in another city.
  3. Once the message goes viral, **20 people show up days later** when the surgery is already over, overcrowding the hospital corridors.
  4. **Fake blood brokers** try to sell blood illegally for exorbitant money.

---

## 🩸 How JeevanSetu Solves This

1. **Hospital Posts an Emergency (SOS):**  
   The duty doctor enters the patient's blood group and hospital room on the app.

2. **The App Does the Math Silently:**  
   The app automatically checks:
   * **Location:** Who is physically within **5 to 10 km** of the hospital.
   * **Blood Compatibility:** Who can clinically donate to this patient (e.g., `O-` can donate to anyone).
   * **Safety Cooldown:** Has the donor rested for at least **90 days** since their last donation (so they don't get sick or anaemic).

3. **Instant Siren Alert on Compatible Donors' Phones:**  
   Only eligible donors nearby hear an emergency siren on their screen. The first donor who taps **"Accept"** locks the request—so no other donors are sent, preventing hospital crowding.

4. **Live GPS Navigation & Bedside Verification:**
   * The app shows a live turn-by-turn road route directly to the emergency ward.
   * When the donor arrives at the patient's bedside, the doctor gives them a **4-digit secret code** (e.g., `#8492`).
   * Entering this code completes the donation, updates their digital badge, and starts their **90-day rest timer**.

Built completely on **free OpenStreetMap and Flutter**, JeevanSetu costs **zero rupees in map fees**, protecting donor health and saving critical lives during emergencies.

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

### 1. 🗺️ Live OpenStreetMap (OSM) Dispatch Radar & Route Navigation
* Interactive free OpenStreetMap rendered via `flutter_map`.
* Real-time road routing polyline rendered dynamically between donor GPS coordinates and hospital emergency triage via open-source **OSRM API** with curved urban waypoint interpolation fallback.
* Visualizes real-time hospital SOS locations with emergency pulsing dispatch radius circles (5 km – 15 km).
* Floating **In-Transit Dispatch HUD** displaying live ETA (mins), distance remaining, and quick action controls.

### 2. 🚗 Live GPS In-Transit Route Simulation Engine (Day 3 Milestone)
* Stepped GPS transit simulation moving the donor marker along calculated OSRM road waypoints in real time.
* Real-time countdown of remaining driving distance (km) and dynamic ETA (minutes).
* Smooth map camera auto-tracking centering on vehicle motion.
* **Automatic Bedside Arrival Detection (<50m):** Triggers audio-visual arrival notification and prompts 4-digit Bedside Handover OTP verification upon reaching the hospital!

### 3. 🚨 Real-Time High-Urgency Emergency Broadcast Modal
* Immediate pop-up alert triggered when an SOS is dispatched in the donor's vicinity.
* Displays emergency pulsing siren, hospital name, patient trauma severity, distance, and clinical compatibility guarantee.
* Quick one-tap **"ACCEPT & RESPOND 🚗"** action to lock ticket and start navigation immediately.

### 4. 🏥 Hospital Authority Command Desk
* Dedicated command console for duty doctors, nurses, and blood bank coordinators.
* Real-time status cards: *Awaiting Donors*, *Responders En Route*, and *Fulfilled Transfusions*.
* Prominent **4-Digit Bedside Handover OTP Box** (`#8492`) for medical staff to verify arriving voluntary donors at the patient's bedside.
* Seamless role toggle between **Donor Mode** and **Hospital Authority Mode** from any screen.

### 5. 🔐 4-Digit Clinical Handover OTP Verification
* Prevents fake or zombie donations: hospital desk issues a unique 4-digit code (e.g. `#8492`).
* Arriving donor enters the code bedside; upon successful validation:
  * Ticket transitions to `FULFILLED` across all network nodes.
  * Donation is officially stamped into the donor's digital medical passport.
  * Medical 90-day safety cooldown timer activates immediately to protect donor health.

### 6. 🪪 Digital Medical Pass & Verified Donation History
* Complete record of verified donations with hospital names, units, and verification OTP badges.
* Real-time 90-day safety cooldown countdown with visual eligibility indicators.
* Dynamic **Clinical Compatibility Matrix** showing exactly which blood groups the user can donate to and receive from.
* Instant simulation controls: toggle cooldown state, switch blood group, and switch between Donor Mode and Hospital Authority Mode.

### 7. ☁️ Offline-First Local Engine & Firebase Cloud Architecture
* **Offline-First Persistence:** Profile, custom blood group, active dispatches, and donation records persist across restarts via `shared_preferences`.
* **Firebase Cloud Sync:** Real-time synchronization via Google Cloud Firestore (`firebase_core`, `cloud_firestore`) with atomic transaction-based concurrency locking to prevent race conditions.
* Built-in **Emergency Influx Simulator** (⚡ button in AppBar) to generate realistic critical emergencies for evaluation and testing.

---

## 🛠️ Technology Stack
* **Frontend / Framework:** [Flutter](https://flutter.dev/) (Dart 3.x, Flutter 3.47+)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Geospatial & Mapping:** 
  * [`flutter_map`](https://pub.dev/packages/flutter_map) (Powered by open-source OpenStreetMap tile servers)
  * [`geolocator`](https://pub.dev/packages/geolocator) (Device GPS positioning & accuracy)
  * [`latlong2`](https://pub.dev/packages/latlong2) (Haversine spherical distance calculations)
  * Open Source Routing Machine (**OSRM**) for turn-by-turn road polyline generation.
* **Storage & Cloud Database:**
  * [`shared_preferences`](https://pub.dev/packages/shared_preferences) for local offline-first storage
  * [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) for real-time cloud multi-device sync
* **Typography & UI:** [Google Fonts (Inter)](https://fonts.google.com/specimen/Inter), Material Design 3

---

## 🏗️ System Architecture

```text
       ┌────────────────────────────────────────────────────────┐
       │                Flutter Mobile App                      │
       │                                                        │
       │   [ Live Map (OSM + Route) ]  [ SOS Alert Feed ]       │
       │   [ Hospital Dispatch Desk ]  [ Medical Pass History ] │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                  AppState Engine                       │
       │                                                        │
       │  • Haversine & OSRM Road Route Calculations            │
       │  • BloodMatrix (ABO & Rh Clinical Compatibility)       │
       │  • Medical Cooldown Checker (>= 90 Days)               │
       │  • 4-Digit Handover OTP Verification Engine            │
       │  • Atomic Concurrency Lock (Avoid Double Dispatch)     │
       └──────────────┬──────────────────────────┬──────────────┘
                      │                          │
                      ▼                          ▼
       ┌────────────────────────┐      ┌────────────────────────┐
       │ Local Storage Service  │      │  Cloud Firestore Sync  │
       │  (SharedPreferences)   │      │  (Real-Time Database)  │
       └────────────────────────┘      └────────────────────────┘
```

---

## 🚀 How to Run the Project Locally

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (Version 3.47+ recommended)
* Google Chrome or an Android device with USB debugging enabled.

### Step-by-Step Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Sibashishbiswal/jeevansetu-blood-network.git
   cd rakshak-blood-network
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Verify code & run automated test suite:**
   ```bash
   flutter analyze
   flutter test
   ```
   *(Expected output: No issues found! All 71 unit, integration & widget tests passed!)*

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
