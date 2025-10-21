# Supabase Architecture Overview

## 📊 Database Schema

```
┌─────────────────────────────────────────────────────────────────┐
│                         CONTENT_SECTIONS                         │
├─────────────────────────────────────────────────────────────────┤
│ id (UUID)                                                        │
│ type (TEXT): 'playlists' | 'albums'                             │
│ title (TEXT): e.g., "Featured Albums"                           │
│ display_order (INT)                                              │
│ is_visible (BOOLEAN)                                             │
└────┬──────────────────────────────────────────────────┬─────────┘
     │                                                   │
     │ One-to-Many                          One-to-Many │
     ▼                                                   ▼
┌─────────────────────────────┐    ┌──────────────────────────────┐
│    FEATURED_PLAYLISTS       │    │     FEATURED_ALBUMS          │
├─────────────────────────────┤    ├──────────────────────────────┤
│ id (UUID)                   │    │ id (UUID)                    │
│ section_id (FK)             │    │ section_id (FK)              │
│ apple_playlist_id (TEXT)    │    │ apple_album_url (TEXT)       │
│ cover_image_url (TEXT)      │    │ apple_album_id (TEXT)        │
│ instrument_image_url (TEXT) │    │ custom_title (TEXT)          │
│ footer_text (TEXT)          │    │ custom_artist (TEXT)         │
│ custom_title (TEXT)         │    │ custom_image_url (TEXT)      │
│ custom_curator (TEXT)       │    │ display_order (INT)          │
│ custom_description (TEXT)   │    │ is_visible (BOOLEAN)         │
│ display_order (INT)         │    └──────────────────────────────┘
│ is_visible (BOOLEAN)        │
└─────────────────────────────┘
```

## 🗂️ Storage Buckets

```
SUPABASE STORAGE
├── playlist-covers (PUBLIC)
│   ├── setaar.jpg
│   ├── santoor.jpg
│   └── kamancheh.jpg
│
└── instrument-images (PUBLIC)
    ├── setaar-instrument.jpg
    ├── santoor-instrument.jpg
    └── kamancheh-instrument.jpg
```

## 🔄 Data Flow

```
┌──────────────┐
│   Supabase   │
│   Database   │
└──────┬───────┘
       │
       │ REST API
       │ (Public Read Access)
       ▼
┌──────────────┐
│ ContentManager│ ◄── Fetches JSON
│  (Swift)      │
└──────┬────────┘
       │
       │ Decoded Models
       ▼
┌──────────────┐
│  App Views   │ ◄── Displays Content
│ (SwiftUI)    │
└──────────────┘
       │
       │ Downloads Images
       ▼
┌──────────────┐
│   Supabase   │
│   Storage    │
└──────────────┘
```

## 📱 Example: Playlist Data Flow

```
1. User Opens App
   └─> ContentManager.fetchContent()

2. Fetch from Supabase
   └─> GET /rest/v1/featured_playlists?select=*

3. Response (JSON):
   {
     "id": "uuid-here",
     "apple_playlist_id": "pl.u-vEe5t44Rjbm",
     "cover_image_url": "https://.../setaar.jpg",
     "instrument_image_url": "https://.../setaar-instrument.jpg",
     "footer_text": "Se Tār | سه تار",
     "custom_title": "The Dance of Silence | رقص سکوت",
     ...
   }

4. Decode to Swift Model
   └─> FeaturedPlaylist struct

5. Update UI
   └─> PlaylistCardView displays with AsyncImage

6. Download Images
   └─> AsyncImage fetches from Supabase Storage URLs
```

## 🔐 Security Setup

```
ROW LEVEL SECURITY (RLS)

┌─────────────────────────────────────────┐
│            PUBLIC ACCESS                 │
│  Anyone can READ (select) content        │
│  ✅ Users can view playlists/albums      │
│  ✅ No authentication required           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│        AUTHENTICATED ACCESS              │
│  Only logged-in users can WRITE          │
│  ✅ You can insert/update/delete         │
│  ❌ Anonymous users cannot modify        │
└─────────────────────────────────────────┘
```

## 🎯 Content Management Workflow

```
YOU (Admin)                    SUPABASE                    APP USERS
     │                              │                             │
     │ 1. Upload Image              │                             │
     ├─────────────────────────────>│                             │
     │    (via Dashboard)            │                             │
     │                              │                             │
     │ 2. Insert/Update Row         │                             │
     ├─────────────────────────────>│                             │
     │    (Table Editor)             │                             │
     │                              │                             │
     │                              │ 3. App Launches             │
     │                              │<────────────────────────────│
     │                              │                             │
     │                              │ 4. Fetch Content            │
     │                              ├────────────────────────────>│
     │                              │    (JSON Response)          │
     │                              │                             │
     │                              │ 5. Display New Content      │
     │                              │    ✅ No app update needed! │
     │                              │                             │
```

## 📦 What Gets Stored Where

```
SUPABASE DATABASE
├── Metadata
│   ├── Playlist IDs
│   ├── Custom titles/descriptions
│   ├── Display order
│   ├── Visibility flags
│   └── Image URLs (references)
│
SUPABASE STORAGE
├── Actual Images
│   ├── Playlist covers (800x800px)
│   └── Instrument icons (200x200px)
│
APP BUNDLE
└── Fallback Data
    └── Local JSON (if Supabase fails)
```

## 🚀 Scaling Considerations

### Current Setup (Free Tier):
- **Database**: Up to 500 MB
- **Storage**: 1 GB (500-1000 images)
- **Bandwidth**: 2 GB/month (~5K image loads)
- **API Requests**: Unlimited reads

### When to Upgrade ($25/month):
- **Storage**: 100 GB
- **Bandwidth**: 200 GB/month
- Good for: 100K+ monthly users

### Performance Optimizations:
1. ✅ Images served via CDN (fast worldwide)
2. ✅ App caches content locally
3. ✅ Database indexes on display_order
4. ✅ Public buckets = no auth overhead

## 🎨 Image Size Guidelines

```
PLAYLIST COVERS          INSTRUMENT IMAGES        ALBUMS
┌─────────────┐         ┌───────────┐            ┌──────────┐
│             │         │           │            │          │
│   800x800   │         │  200x200  │            │  400x400 │
│             │         │           │            │  (Apple) │
│  < 500 KB   │         │  < 200 KB │            └──────────┘
│             │         │           │
│   JPG/PNG   │         │  PNG/JPG  │
│             │         │           │
└─────────────┘         └───────────┘
```

## ✅ Next Steps

1. **Database**: Run the migration SQL (5 minutes)
2. **Storage**: Create buckets and upload images (10 minutes)
3. **Code**: Integrate with Swift app (I'll help!)
4. **Test**: Verify content appears in app
5. **Deploy**: Ship to App Store!

Once you're ready, I'll create the Swift implementation! 🎉

