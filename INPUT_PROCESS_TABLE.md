# SAFRA App - Input Process Table (4 Table Levels)

## 📊 TABLE HIERARCHY OVERVIEW

### Level 1: Core User Data
**Table**: `user_profiles` - Foundation table for all user information

### Level 2: Evidence Data  
**Table**: `evidence` - User-generated evidence and incident reports

### Level 3: Community Data
**Table**: `community_messages` - Public community interactions

### Level 4: Storage Data
**Table**: `storage.objects` - File storage for media uploads

---

## 🎯 LEVEL 1: USER_PROFILES TABLE

| Input Field | Data Type | Process Flow | Validation Rules | UI Source | Service Layer | API Endpoint |
|-------------|-----------|--------------|------------------|-----------|---------------|--------------|
| **user_id** | UUID | Auto-generated from auth.users | Must match authenticated user | Login Screen | UserProfileService.getOrCreateProfile() | auth.uid() |
| **full_name** | TEXT | User input → Validation → Storage | Max 255 chars, optional | Profile Edit | UserProfileService.updateProfile() | supabase.from('user_profiles').upsert() |
| **phone_number** | TEXT | Phone input → Format validation → Storage | E.164 format, optional | Profile Edit | UserProfileService.updateProfile() | supabase.from('user_profiles').upsert() |
| **date_of_birth** | DATE | Date picker → Age validation → Storage | Must be 13+ years old | Profile Edit | UserProfileService.updateProfile() | supabase.from('user_profiles').upsert() |
| **gender** | TEXT | Dropdown selection → Constraint check → Storage | 'Male', 'Female', 'Other', 'Prefer not to say' | Profile Edit | UserProfileService.updateProfile() | supabase.from('user_profiles').upsert() |
| **bio** | TEXT | Text input → Length check → Storage | Max 500 chars, optional | Profile Edit | UserProfileService.updateProfile() | supabase.from('user_profiles').upsert() |
| **profile_image_url** | TEXT | Image upload → URL generation → Storage | Valid image URL, optional | Profile Edit | UserProfileService.uploadProfileImage() | storage.from('profiles').upload() |
| **emergency_contact_name** | TEXT | Contact picker → Name extraction → Storage | Max 255 chars, optional | SOS Setup | ContactService.selectContact() | supabase.from('user_profiles').upsert() |
| **emergency_contact_phone** | TEXT | Contact picker → Phone extraction → Storage | Valid phone format | SOS Setup | ContactService.selectContact() | supabase.from('user_profiles').upsert() |
| **created_at** | TIMESTAMP | Auto-generated on insert | Cannot be modified | System | Database trigger | DEFAULT NOW() |
| **updated_at** | TIMESTAMP | Auto-updated on changes | Updates automatically | System | Database trigger | BEFORE UPDATE trigger |

### Process Flow Diagram:
```
User Input → Form Validation → Service Layer → Supabase API → Database
     ↓              ↓              ↓              ↓              ↓
Profile Form → Field Checks → UserProfileService → RLS Policies → user_profiles
```

---

## 🎯 LEVEL 2: EVIDENCE TABLE

| Input Field | Data Type | Process Flow | Validation Rules | UI Source | Service Layer | API Endpoint |
|-------------|-----------|--------------|------------------|-----------|---------------|--------------|
| **user_id** | UUID | Auto-generated from auth.users | Must match authenticated user | Evidence Upload | EvidenceService.createEvidence() | auth.uid() |
| **category** | TEXT | Category picker → Constraint validation → Storage | 'Harassment', 'Assault', 'Stalking', 'Theft', 'Accident', 'Other' | Evidence Upload | EvidenceService.createEvidence() | supabase.from('evidence').insert() |
| **severity** | NUMERIC(2,1) | Slider input → Range validation → Storage | 1.0 to 5.0 range | Evidence Upload | EvidenceService.createEvidence() | supabase.from('evidence').insert() |
| **incident_date** | TIMESTAMP | DateTime picker → Past date validation → Storage | Cannot be future date | Evidence Upload | EvidenceService.createEvidence() | supabase.from('evidence').insert() |
| **location** | TEXT | Location services → Address formatting → Storage | Valid address string | Evidence Upload | LocationService.getCurrentAddress() | supabase.from('evidence').insert() |
| **notes** | TEXT | Text input → Length validation → Storage | Max 1000 chars, optional | Evidence Upload | EvidenceService.createEvidence() | supabase.from('evidence').insert() |
| **tags** | TEXT[] | Tag input → Array validation → Storage | Max 10 tags, 50 chars each | Evidence Upload | EvidenceService.createEvidence() | supabase.from('evidence').insert() |
| **photo_urls** | TEXT[] | Camera/Gallery → Upload → URL array generation | Valid image URLs, max 5 photos | Evidence Upload | EvidenceService.uploadMedia() | storage.from('evidence').upload() |
| **video_urls** | TEXT[] | Camera/Gallery → Upload → URL array generation | Valid video URLs, max 2 videos | Evidence Upload | EvidenceService.uploadMedia() | storage.from('evidence').upload() |
| **is_anonymous** | BOOLEAN | Toggle switch → Boolean validation → Storage | true/false only | Evidence Upload | EvidenceService.createEvidence() | supabase.from('evidence').insert() |
| **created_at** | TIMESTAMP | Auto-generated on insert | Cannot be modified | System | Database trigger | DEFAULT NOW() |
| **updated_at** | TIMESTAMP | Auto-updated on changes | Updates automatically | System | Database trigger | BEFORE UPDATE trigger |

### Process Flow Diagram:
```
Evidence Form → Media Upload → Location Capture → Service Layer → Database
      ↓               ↓              ↓              ↓              ↓
Category/Notes → Photo/Video → GPS/Address → EvidenceService → evidence
```

---

## 🎯 LEVEL 3: COMMUNITY_MESSAGES TABLE

| Input Field | Data Type | Process Flow | Validation Rules | UI Source | Service Layer | API Endpoint |
|-------------|-----------|--------------|------------------|-----------|---------------|--------------|
| **user_id** | UUID | Auto-generated from auth.users | Must match authenticated user | Community Screen | CommunityService.sendMessage() | auth.uid() |
| **user_email** | TEXT | Extracted from auth.users | Must match user's email | Community Screen | CommunityService.sendMessage() | auth.users()->email |
| **user_name** | TEXT | Extracted from user_profiles.full_name | Fallback to email prefix | Community Screen | CommunityService.sendMessage() | user_profiles.full_name |
| **message** | TEXT | Text input → Content validation → Storage | Max 500 chars, not empty | Community Screen | CommunityService.sendMessage() | supabase.from('community_messages').insert() |
| **created_at** | TIMESTAMP | Auto-generated on insert | Cannot be modified | System | Database trigger | DEFAULT NOW() |

### Process Flow Diagram:
```
Message Input → Content Validation → User Info Extraction → Service Layer → Database
      ↓                ↓                    ↓                  ↓              ↓
Chat Input → Length Check → Profile Lookup → CommunityService → community_messages
```

---

## 🎯 LEVEL 4: STORAGE.OBJECTS TABLE (Media Files)

| Input Field | Data Type | Process Flow | Validation Rules | UI Source | Service Layer | API Endpoint |
|-------------|-----------|--------------|------------------|-----------|---------------|--------------|
| **bucket_id** | TEXT | Fixed to 'evidence' bucket | Must be 'evidence' | Evidence Upload | StorageService.uploadFile() | storage.from('evidence').upload() |
| **name** | TEXT | Generated path: user_id/timestamp_filename | Unique filename | Evidence Upload | StorageService.generateFilePath() | user_id + '/' + timestamp + '_' + filename |
| **owner** | UUID | Auto-generated from auth.uid() | Must be authenticated user | Evidence Upload | StorageService.uploadFile() | auth.uid() |
| **metadata** | JSONB | File metadata (size, type, dimensions) | Valid JSON structure | Evidence Upload | StorageService.extractMetadata() | {size: number, type: string, width: number, height: number} |

### Process Flow Diagram:
```
File Selection → Metadata Extraction → Path Generation → Upload Service → Storage
      ↓                ↓                  ↓                  ↓              ↓
Photo/Video → File Info → User Path → StorageService → storage.objects
```

---

## 🔗 RELATIONSHIP MAPPING

### Primary Key → Foreign Key Relationships:
```
auth.users.id (PK) → user_profiles.user_id (FK)
auth.users.id (PK) → evidence.user_id (FK)  
auth.users.id (PK) → community_messages.user_id (FK)
auth.users.id (PK) → storage.objects.owner (FK)
user_profiles.user_id (FK) → community_messages.user_name (derived)
```

### Data Flow Between Tables:
```
User Registration → user_profiles (auto-created)
     ↓
Evidence Upload → evidence + storage.objects (linked via URLs)
     ↓
Community Post → community_messages (with user info)
```

---

## 🛡️ SECURITY & VALIDATION LAYERS

### 1. Application Layer Validation
- Form field validation (length, format, range)
- File type and size validation
- Input sanitization

### 2. Service Layer Validation  
- Business logic validation
- User permission checks
- Data transformation

### 3. Database Layer Validation
- RLS (Row Level Security) policies
- Check constraints (gender, category, severity)
- Data type constraints
- Foreign key constraints

### 4. Storage Layer Validation
- File upload permissions
- Storage bucket policies
- File size and type restrictions

---

## 📈 PERFORMANCE OPTIMIZATION

### Indexes Created:
```sql
idx_user_profiles_user_id (user_id)
idx_user_profiles_updated_at (updated_at)
idx_evidence_user_id (user_id)
idx_evidence_created_at (created_at)
idx_community_messages_created_at (created_at)
idx_community_messages_user_id (user_id)
```

### Query Optimization:
- Indexed foreign keys for fast joins
- Timestamp indexes for chronological queries
- User-specific indexes for personal data retrieval

---

## 🔄 COMPLETE INPUT PROCESS FLOW

### User Registration Flow:
```
1. User signs up via Supabase Auth
2. get_or_create_user_profile() function triggered
3. user_profiles row created with basic info
4. User can update profile through Profile Edit screen
```

### Evidence Upload Flow:
```
1. User fills evidence form (Evidence Upload Screen)
2. Media files uploaded to storage.evidence bucket
3. File URLs returned and stored in evidence.photo_urls/video_urls
4. evidence row created with all form data + URLs
```

### Community Message Flow:
```
1. User types message (Community Screen)
2. user_name extracted from user_profiles.full_name
3. Message sent to community_messages table
4. Real-time subscription updates all connected clients
```

This table structure provides a complete 4-level hierarchy with clear input processes, validation rules, and data flow mapping for your SAFRA app's database architecture.