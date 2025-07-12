# 📦 Backend Development TODO

This TODO file outlines the core tasks for building the backend architecture of the Simple Miles app, focusing on scalable, local-first infrastructure with future cloud integration.

---

## 🔧 Phase 1: Core Trip Data System (Local Storage MVP)

### 🗂️ Data Modeling
- [ ] Define `TripModel`
  - [ ] `tripId: UUID`
  - [ ] `userId: String`
  - [ ] `startTimestamp: Date`
  - [ ] `endTimestamp: Date`
  - [ ] `distance: Double`
  - [ ] `route: [CLLocationCoordinate2D]` or compressed polyline
  - [ ] `purpose: String` (business/personal/unclassified)
  
### 💾 Local Database Setup
- [ ] Choose and initialize CoreData stack
- [ ] Create CoreData entities & attributes for `TripModel`
- [ ] Create helper methods for saving, updating, deleting trips

### 🛰️ Location Tracking Engine
- [ ] Configure `CLLocationManager` for background updates
- [ ] Implement trip start/stop logic
- [ ] Capture real-time location points during trip
- [ ] Compress/store route for minimal footprint
- [ ] Save finalized trip to CoreData

---

## ☁️ Phase 2: Cloud Sync (Post-MVP)

### 🔄 Cloud Syncing Logic
- [ ] Choose backend service (Firebase, Supabase, custom API)
- [ ] Setup secure sync of local trips to cloud
- [ ] Trigger sync:
  - [ ] On Wi-Fi
  - [ ] On app open/resume
  - [ ] Manual sync button

### 🔐 Auth Integration
- [ ] Sync tied to authenticated user ID
- [ ] Handle login/signup with session linking

---

## 🧠 Phase 3: Classification, Filtering & Analytics

### 🏷️ Trip Classification
- [ ] UI for tagging trips (Business/Personal/Other)
- [ ] Store classification state locally

### 📆 Filtering System
- [ ] Filter trips by date, time, type, or distance
- [ ] Add query logic in local DB layer

### 📊 Metrics & Insights (Future Cloud Scope)
- [ ] Average trip length
- [ ] Most visited areas
- [ ] Driving behavior analytics (time of day, distance/day)
- [ ] User opt-in data aggregation

---

## 🧪 Testing
- [ ] Unit tests for trip model validation
- [ ] Unit tests for location update logic
- [ ] Unit tests for trip classification
- [ ] Integration tests for cloud sync process

---

## 🧱 Infrastructure Considerations
- [ ] Ensure data privacy + user opt-in for analytics
- [ ] Keep storage minimal + optimize local usage
- [ ] Design schema for future scalability
- [ ] Prepare structure for potential multi-device syncing

---

## ✍️ Notes
- App should function entirely offline
- Background tracking must be battery-efficient
- All syncing and heavy computation should defer until low-activity or Wi-Fi
- Use modular design to isolate sync logic, DB logic, and trip processing

