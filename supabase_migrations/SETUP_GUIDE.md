# Supabase Setup Guide for Rubatar CMS

This guide will walk you through setting up the Supabase backend for managing your app's content dynamically.

## 📋 Overview

You'll be able to manage:
- **Playlists**: Add/edit playlists with custom images, titles, and descriptions
- **Albums**: Add/edit featured albums from Apple Music
- **Sections**: Organize content into sections (e.g., "Featured Albums", "Playlists by instrument")

All changes will reflect in the app **without needing an app update**!

---

## 🚀 Step 1: Run the Database Migration

1. **Open Supabase Dashboard**
   - Go to: https://app.supabase.com
   - Select your project: `pspybykovwrfdxpkjpzd`

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Migration**
   - Open the file: `001_create_content_management_schema.sql`
   - Copy the entire contents
   - Paste into Supabase SQL Editor
   - Click "Run" button (or press Cmd+Enter)

4. **Verify Success**
   - You should see: "Success. No rows returned"
   - Check "Table Editor" in left sidebar - you should see:
     - `content_sections`
     - `featured_playlists`
     - `featured_albums`

---

## 📦 Step 2: Create Storage Buckets

Storage buckets will hold your images (playlist covers, instrument images).

### 2.1: Create Buckets

1. **Navigate to Storage**
   - Click "Storage" in the left sidebar
   - Click "New bucket"

2. **Create `playlist-covers` bucket**
   - Name: `playlist-covers`
   - Public bucket: ✅ **YES** (check this box)
   - Click "Create bucket"

3. **Create `instrument-images` bucket**
   - Name: `instrument-images`
   - Public bucket: ✅ **YES**
   - Click "Create bucket"

### 2.2: Configure Bucket Policies (Already set by default for public buckets)

The buckets are now ready to accept images!

---

## 🖼️ Step 3: Upload Images

You need to upload 6 images total:

### Playlist Covers (3 images):
1. **Setaar** (`setaar.jpg`) - Main playlist cover for Se Tār
2. **Santoor** (`santoor.jpg`) - Main playlist cover for Santoor
3. **Kamancheh** (`kamancheh.jpg`) - Main playlist cover for Kamancheh

### Instrument Images (3 images):
1. **SetaarInstrument** (`setaar-instrument.jpg`) - Footer image for Se Tār
2. **SantoorInstrument** (`santoor-instrument.jpg`) - Footer image for Santoor
3. **KamanchehInstrument** (`kamancheh-instrument.jpg`) - Footer image for Kamancheh

### Upload Process:

1. **Go to Storage → `playlist-covers`**
   - Click "Upload file"
   - Select `setaar.jpg`, `santoor.jpg`, `kamancheh.jpg`
   - Click "Upload"

2. **Go to Storage → `instrument-images`**
   - Click "Upload file"
   - Select `setaar-instrument.jpg`, `santoor-instrument.jpg`, `kamancheh-instrument.jpg`
   - Click "Upload"

### Get Image URLs:

For each uploaded image:
1. Click on the image name
2. Click "Copy URL" button
3. Your URLs will look like:
   ```
   https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/setaar.jpg
   ```

---

## ✏️ Step 4: Update Database with Image URLs

The migration includes seed data with placeholder URLs. You need to update them with your actual image URLs.

### 4.1: Get Your Image URLs

After uploading, you'll have 6 URLs like:
```
Playlist Covers:
- https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/setaar.jpg
- https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/santoor.jpg
- https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/kamancheh.jpg

Instrument Images:
- https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/setaar-instrument.jpg
- https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/santoor-instrument.jpg
- https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/kamancheh-instrument.jpg
```

### 4.2: Update the Migration File (Before Running)

**IMPORTANT**: Before running the migration in Step 1, open `001_create_content_management_schema.sql` and update the seed data URLs (around line 185) with your actual image URLs.

OR

### 4.3: Update Manually in Supabase Dashboard

1. Go to **Table Editor → `featured_playlists`**
2. Click on a row to edit
3. Update the `cover_image_url` and `instrument_image_url` fields
4. Click "Save"
5. Repeat for all 3 playlists

---

## 🔍 Step 5: Verify Your Setup

### 5.1: Check Tables

**Table Editor → `content_sections`**
Should have 2 rows:
- "Playlists by instrument" (type: playlists)
- "Featured Albums" (type: albums)

**Table Editor → `featured_playlists`**
Should have 3 rows with your playlists and image URLs.

### 5.2: Test API Access

Run this in your browser (replace with your project URL):
```
https://pspybykovwrfdxpkjpzd.supabase.co/rest/v1/featured_playlists?select=*
```

Add this header if needed:
```
apikey: YOUR_ANON_KEY
```

You should see JSON with your playlists!

---

## 📱 Step 6: Integrate with iOS App

Now that the database is set up, the next steps are:

1. ✅ Create Swift models to match database schema
2. ✅ Build `ContentManager` to fetch data from Supabase
3. ✅ Update UI to use dynamic content
4. ✅ Add caching for offline support

**I'll help you implement these in the next steps!**

---

## 🎨 Image Recommendations

For best results, use these image specifications:

### Playlist Covers:
- **Resolution**: 800x800px minimum (1200x1200px recommended)
- **Format**: JPG or PNG
- **File size**: < 500 KB each
- **Aspect ratio**: 1:1 (square)

### Instrument Images:
- **Resolution**: 200x200px minimum (400x400px recommended)
- **Format**: PNG (for transparency) or JPG
- **File size**: < 200 KB each
- **Aspect ratio**: 1:1 (square)

---

## 🔧 Managing Content (After Setup)

### Adding a New Playlist:

1. **Go to Table Editor → `featured_playlists`**
2. Click "Insert row"
3. Fill in:
   - `section_id`: Copy from existing playlist row
   - `apple_playlist_id`: Your Apple Music playlist ID (e.g., `pl.u-xxxxx`)
   - `cover_image_url`: Upload image to Storage, copy URL
   - `instrument_image_url`: Upload image to Storage, copy URL
   - `footer_text`: e.g., "Tar | تار"
   - `display_order`: 4 (or next number)
4. Click "Save"
5. **App updates automatically!** 🎉

### Adding a New Album:

1. **Go to Table Editor → `featured_albums`**
2. Click "Insert row"
3. Fill in:
   - `section_id`: Copy from content_sections where type='albums'
   - `apple_album_url`: Full Apple Music URL
   - `display_order`: Next number
4. Click "Save"

### Creating New Sections:

1. **Go to Table Editor → `content_sections`**
2. Click "Insert row"
3. Fill in:
   - `type`: 'playlists' or 'albums'
   - `title`: e.g., "New Releases"
   - `display_order`: Next number
4. Click "Save"
5. Add playlists/albums with this `section_id`

---

## 🛡️ Security Notes

- ✅ **Public Read Access**: Anyone can read content (needed for app)
- ✅ **Authenticated Write Access**: Only logged-in users can edit (secure)
- ✅ **RLS Policies**: Row Level Security is enabled
- ✅ **Public Storage**: Images are publicly accessible (needed for app)

To manage content, you'll need to authenticate (use Supabase Auth or dashboard).

---

## ❓ Troubleshooting

### "No rows returned" error
- This is normal for CREATE TABLE statements
- Check Table Editor to verify tables exist

### Images not loading
- Verify bucket is **public**
- Check URL format matches: `https://PROJECT.supabase.co/storage/v1/object/public/BUCKET/FILE`
- Test URL in browser - should display image

### Can't see tables in Table Editor
- Refresh the page
- Check SQL Editor for error messages
- Verify migration ran successfully

### Policy errors
- Make sure RLS policies are created
- Check that buckets are marked as "public"

---

## 📞 Need Help?

If you run into issues:
1. Check Supabase logs in Dashboard → Database → Logs
2. Verify all steps were completed in order
3. Test API endpoints in browser/Postman

---

## ✅ Next Steps

Once this setup is complete, I'll help you:
1. Create Swift models
2. Build ContentManager service
3. Integrate with your existing UI
4. Add image caching
5. Implement fallback for offline mode

Let me know when you've completed the setup! 🚀

