# SAFRA App - Dataflow: User to Processing to Tables

## 🔄 COMPLETE DATAFLOW OVERVIEW

```
USER INTERFACE → FLUTTER SERVICES → SUPABASE API → DATABASE TABLES
     ↓                    ↓                  ↓                ↓
Screens/Forms    Business Logic      REST/Realtime      8 Core Tables
```

---

## 📱 LEVEL 1: USER INTERFACE LAYER

### Input Sources:
- **Profile Screen** → User data entry
- **Evidence Upload Screen** → Incident reporting
- **Community Screen** → Messages & reports
- **SOS Screen** → Emergency activation
- **Settings Screen** → Preferences

---

## ⚙️ LEVEL 2: SERVICE PROCESSING LAYER

### Core Services Flow:

```
USER INPUT → VALIDATION → TRANSFORMATION → API CALL → RESPONSE HANDLING
```

#### **UserProfileService** (Level 1 Tables)
```
Profile Form Input → Field Validation → Data Sanitization → Supabase Upsert → user_profiles
Biometric Toggle → Permission Check → Settings Update → user_settings
```

#### **EvidenceService** (Level 2 Tables)
```
Evidence Form → Category Validation → Location Processing → Media Upload → evidence + evidence_metadata
Photo/Video → File Validation → Storage Upload → URL Generation → evidence.photo_urls
```

#### **CommunityService** (Level 3 Tables)
```
Message Input → Content Validation → User Info Lookup → Realtime Insert → community_messages
Report Form → Severity Assessment → Anonymous Flag → Location Data → community_reports
```

#### **LocationService** (Level 4 Tables)
```
GPS Signal → Accuracy Check → Address Lookup → Coordinate Storage → location_history
SOS Activation → Contact Processing → SMS Generation → History Logging → sos_history
```

---

## 🗄️ LEVEL 3: DATABASE STORAGE LAYER

### Table Dataflow Mapping:

## **USER → user_profiles FLOW**
```
┌─────────────────────────────────────────────────────────────┐
│ USER INTERFACE: Profile Screen                            │
├─────────────────────────────────────────────────────────────┤
│ • Full Name Input                                           │
│ • Phone Number Entry                                        │
│ • Date of Birth Picker                                      │
│ • Gender Selection                                          │
│ • Bio Text Area                                             │
│ • Profile Image Upload                                      │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SERVICE: UserProfileService                                 │
├─────────────────────────────────────────────────────────────┤
│ • Field Validation (length, format)                        │
│ • Phone Number E.164 Formatting                              │
│ • Age Verification (13+ years)                              │
│ • Image Upload to Storage                                   │
│ • Data Sanitization                                         │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SUPABASE API: user_profiles table                          │
├─────────────────────────────────────────────────────────────┤
│ • RLS Policy: auth.uid() = user_id                         │
│ • Unique constraint on user_id                             │
│ • Auto-generated UUID primary key                          │
│ • Timestamp auto-updates                                     │
└─────────────────────────────────────────────────────────────┘
```

## **EVIDENCE → evidence + evidence_metadata FLOW**
```
┌─────────────────────────────────────────────────────────────┐
│ USER INTERFACE: Evidence Upload Screen                     │
├─────────────────────────────────────────────────────────────┤
│ • Incident Title Input                                      │
│ • Category Selection (Harassment, Assault, etc.)          │
│ • Severity Slider (1-5)                                   │
│ • Date/Time Picker                                        │
│ • Location Capture (GPS/Manual)                           │
│ • Photo/Video Upload (5 photos, 2 videos max)               │
│ • Notes Text Area                                          │
│ • Anonymous Toggle                                         │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SERVICE: EvidenceService                                    │
├─────────────────────────────────────────────────────────────┤
│ • Category Validation (CHECK constraint)                   │
│ • Severity Range Validation (1.0-5.0)                      │
│ • Past Date Validation                                      │
│ • Location Accuracy Check                                   │
│ • Media File Type Validation                               │
│ • Storage Upload (evidence bucket)                         │
│ • URL Array Generation                                       │
│ • Anonymous Flag Processing                                  │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SUPABASE API: evidence + evidence_metadata tables          │
├─────────────────────────────────────────────────────────────┤
│ evidence table:                                             │
│ • Foreign key: user_id → auth.users(id)                    │
│ • CHECK constraints: category, severity, incident_date       │
│ • Array fields: photo_urls[], video_urls[], tags[]          │
│ • Default: is_anonymous = true                             │
│                                                             │
│ evidence_metadata table:                                    │
│ • Foreign key: evidence_id → evidence(id)                  │
│ • JSONB field: device_info                                   │
│ • Environmental data: weather, lighting, crowd              │
│ • Witness and response tracking                              │
└─────────────────────────────────────────────────────────────┘
```

## **COMMUNITY → community_messages + community_reports FLOW**
```
┌─────────────────────────────────────────────────────────────┐
│ USER INTERFACE: Community Screen                           │
├─────────────────────────────────────────────────────────────┤
│ • Message Input Field                                       │
│ • Message Type Selection (general, alert, safety_tip)    │
│ • Location Hint (Optional)                                   │
│ • Report Form (Separate)                                    │
│ • Severity Assessment                                        │
│ • Anonymous Report Option                                   │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SERVICE: CommunityService                                   │
├─────────────────────────────────────────────────────────────┤
│ • Message Length Validation (500 char max)                 │
│ • User Name Lookup (user_profiles.full_name)               │
│ • User Avatar URL Retrieval                                  │
│ • Real-time Subscription Handling                           │
│ • Report Type Classification                                │
│ • Location Validation for Reports                            │
│ • Anonymous User ID Handling                                 │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SUPABASE API: community_messages + community_reports       │
├─────────────────────────────────────────────────────────────┤
│ community_messages table:                                  │
│ • RLS: Public read, authenticated insert                    │
│ • Self-referencing: parent_message_id                       │
│ • Counters: likes_count, replies_count                      │
│ • Edit tracking: is_edited, edited_at                      │
│                                                             │
│ community_reports table:                                     │
│ • Anonymous support (is_anonymous = true)                   │
│ • Expiration tracking (expires_at)                           │
│ • Verification workflow (is_verified, verification_source) │
│ • Status tracking (pending, verified, rejected, expired)    │
└─────────────────────────────────────────────────────────────┘
```

## **SAFETY → emergency_contacts + sos_history + location_history FLOW**
```
┌─────────────────────────────────────────────────────────────┐
│ USER INTERFACE: SOS Screen + Background Services          │
├─────────────────────────────────────────────────────────────┤
│ • SOS Button Activation                                     │
│ • Shake Gesture Detection                                    │
│ • Contact Selection                                         │
│ • Location Permission                                       │
│ • Background Location Updates                               │
│ • Battery Level Monitoring                                   │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SERVICE: LocationService + ContactService + SMSService     │
├─────────────────────────────────────────────────────────────┤
│ • GPS Location Acquisition                                   │
│ • Reverse Geocoding (Address Lookup)                        │
│ • Contact Permission Validation                             │
│ • SMS Message Generation                                     │
│ • Location Accuracy Assessment                              │
│ • Battery Optimization                                       │
│ • Speed and Heading Calculation                             │
│ • Safety Location Flagging                                   │
└─────────────────────────┬─────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ SUPABASE API: emergency_contacts + sos_history +             │
│ location_history tables                                      │
├─────────────────────────────────────────────────────────────┤
│ emergency_contacts table:                                   │
│ • Priority ordering (1-5)                                  │
│ • Notification tracking                                      │
│ • Unique constraint: user_id + contact_phone              │
│ • Active/Inactive status                                     │
│                                                             │
│ sos_history table:                                          │
│ • Multiple activation methods                               │
│ • Response time tracking                                     │
│ • Contact notification metrics                              │
│ • Test vs Real activation flag                              │
│                                                             │
│ location_history table:                                     │
│ • High-frequency location updates                          │
│ • Speed and heading tracking                                │
│ • Battery level correlation                                 │
│ • Safety location classification                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 CROSS-TABLE DATA RELATIONSHIPS

### **Primary Key Flows:**
```
auth.users.id (PK)
    ├──→ user_profiles.user_id (FK)
    ├──→ user_settings.user_id (FK)
    ├──→ evidence.user_id (FK)
    ├──→ community_messages.user_id (FK)
    ├──→ community_reports.user_id (FK)
    ├──→ emergency_contacts.user_id (FK)
    ├──→ sos_history.user_id (FK)
    └──→ location_history.user_id (FK)

evidence.id (PK)
    └──→ evidence_metadata.evidence_id (FK)

community_messages.id (PK)
    └──→ community_messages.parent_message_id (Self FK)
```

### **Data Synchronization Flows:**
```
User Registration → Auto-create user_profiles → Auto-create user_settings
Profile Update → Update user_profiles → Sync to community_messages.user_name
Evidence Upload → Create evidence → Create evidence_metadata → Upload to storage
SOS Activation → Create sos_history → Update location_history → Notify emergency_contacts
Community Post → Create community_messages → Update user activity → Realtime broadcast
```

---

## 🔄 REAL-TIME DATA FLOWS

### **Supabase Realtime Subscriptions:**
```
community_messages → Real-time broadcast → All connected clients
evidence (user's own) → Private updates → User's device only
community_reports → Public updates → Nearby users
sos_history → Emergency broadcast → Emergency contacts
location_history → Background updates → Safety monitoring
```

---

## 🛡️ SECURITY VALIDATION PIPELINE

### **Multi-Layer Validation:**
```
User Input → App Layer Validation → Service Layer → API Layer → Database Constraints
    ↓              ↓                    ↓            ↓               ↓
Form Rules → Flutter Validation → Business Logic → RLS Policies → Check Constraints
```

### **Authentication Flow:**
```
User Login → Supabase Auth → JWT Token → API Requests → RLS Policies → Data Access
    ↓           ↓             ↓            ↓              ↓              ↓
OAuth/OTP → auth.users → auth.uid() → All Tables → Row Level → CRUD Operations
```

---

## 📊 DATA TRANSFORMATION SUMMARY

| User Input | Service Processing | Database Storage |
|------------|-------------------|------------------|
| **Profile Form** → Field validation + image upload → `user_profiles` + `storage.objects` |
| **Evidence Form** → Media upload + location processing → `evidence` + `evidence_metadata` + `storage.objects` |
| **Community Message** → Content validation + user lookup → `community_messages` |
| **SOS Activation** → Location capture + contact notification → `sos_history` + `location_history` |
| **Contact Addition** → Phone validation + priority ordering → `emergency_contacts` |
| **Location Update** → GPS processing + safety assessment → `location_history` |

---

## 🎯 COMPLETE DATA LIFECYCLE

```
USER INTERFACE → SERVICE LAYER → SUPABASE API → DATABASE TABLES → REALTIME SYNC → USER INTERFACE
     ↓                  ↓              ↓                ↓                ↓              ↓
Forms/Buttons → Business Logic → REST/GraphQL → 8 Core Tables → WebSocket → Updated UI
```

This comprehensive dataflow shows how every user interaction flows through the complete SAFRA app architecture, from initial input through processing to final database storage and real-time synchronization!