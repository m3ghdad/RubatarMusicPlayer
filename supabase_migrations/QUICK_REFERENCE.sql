-- =====================================================
-- QUICK REFERENCE: Common Supabase Operations
-- =====================================================
-- Use these queries for common content management tasks
-- =====================================================

-- =====================================================
-- 1. VIEW ALL CONTENT
-- =====================================================

-- View all sections
SELECT * FROM content_sections ORDER BY display_order;

-- View all playlists
SELECT * FROM featured_playlists ORDER BY display_order;

-- View all albums
SELECT * FROM featured_albums ORDER BY display_order;

-- View everything together (using the view)
SELECT * FROM v_app_content;

-- =====================================================
-- 2. ADD NEW PLAYLIST
-- =====================================================

-- First, get the section_id for playlists
SELECT id FROM content_sections WHERE type = 'playlists';

-- Then insert the new playlist (replace the section_id and URLs)
INSERT INTO featured_playlists (
    section_id,
    apple_playlist_id,
    cover_image_url,
    instrument_image_url,
    footer_text,
    custom_title,
    custom_curator,
    custom_description,
    display_order
) VALUES (
    'YOUR_SECTION_ID_HERE', -- Get from query above
    'pl.u-YOUR_PLAYLIST_ID', -- Apple Music playlist ID
    'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/your-image.jpg',
    'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/your-instrument.jpg',
    'Your Instrument | نام فارسی',
    'Your Playlist Title',
    'Your Curator Name',
    'Your playlist description here.',
    4 -- Display order (increment from last playlist)
);

-- =====================================================
-- 3. ADD NEW ALBUM
-- =====================================================

-- First, get the section_id for albums
SELECT id FROM content_sections WHERE type = 'albums';

-- Then insert the new album
INSERT INTO featured_albums (
    section_id,
    apple_album_url,
    display_order
) VALUES (
    'YOUR_SECTION_ID_HERE',
    'https://music.apple.com/us/album/your-album/123456789',
    1
);

-- =====================================================
-- 4. UPDATE PLAYLIST
-- =====================================================

-- Update playlist image URLs
UPDATE featured_playlists
SET 
    cover_image_url = 'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/new-image.jpg',
    instrument_image_url = 'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/new-instrument.jpg'
WHERE apple_playlist_id = 'pl.u-vEe5t44Rjbm';

-- Update playlist metadata
UPDATE featured_playlists
SET 
    custom_title = 'New Title',
    custom_description = 'New description',
    footer_text = 'New Footer Text'
WHERE apple_playlist_id = 'pl.u-vEe5t44Rjbm';

-- =====================================================
-- 5. REORDER PLAYLISTS
-- =====================================================

-- Change display order of playlists
UPDATE featured_playlists SET display_order = 1 WHERE apple_playlist_id = 'pl.u-vEe5t44Rjbm';
UPDATE featured_playlists SET display_order = 2 WHERE apple_playlist_id = 'pl.u-AqK9HDDXK5a';
UPDATE featured_playlists SET display_order = 3 WHERE apple_playlist_id = 'pl.u-bvj8T00GXMg';

-- =====================================================
-- 6. HIDE/SHOW CONTENT
-- =====================================================

-- Hide a playlist (won't appear in app)
UPDATE featured_playlists
SET is_visible = false
WHERE apple_playlist_id = 'pl.u-vEe5t44Rjbm';

-- Show it again
UPDATE featured_playlists
SET is_visible = true
WHERE apple_playlist_id = 'pl.u-vEe5t44Rjbm';

-- Hide entire section
UPDATE content_sections
SET is_visible = false
WHERE type = 'albums';

-- =====================================================
-- 7. DELETE CONTENT
-- =====================================================

-- Delete a specific playlist
DELETE FROM featured_playlists
WHERE apple_playlist_id = 'pl.u-vEe5t44Rjbm';

-- Delete a specific album
DELETE FROM featured_albums
WHERE apple_album_url = 'https://music.apple.com/us/album/...';

-- Delete entire section (CASCADE will delete related playlists/albums)
DELETE FROM content_sections
WHERE type = 'albums';

-- =====================================================
-- 8. CREATE NEW SECTION
-- =====================================================

-- Add a new section (e.g., "New Releases")
INSERT INTO content_sections (type, title, display_order) VALUES
    ('playlists', 'New Releases', 3);

-- Then add playlists to this new section using the section_id

-- =====================================================
-- 9. BULK OPERATIONS
-- =====================================================

-- Add multiple playlists at once
INSERT INTO featured_playlists (
    section_id, apple_playlist_id, cover_image_url, instrument_image_url,
    footer_text, custom_title, custom_curator, custom_description, display_order
) VALUES
    ('section-id-here', 'pl.u-id1', 'url1', 'url1', 'text1', 'title1', 'curator1', 'desc1', 1),
    ('section-id-here', 'pl.u-id2', 'url2', 'url2', 'text2', 'title2', 'curator2', 'desc2', 2),
    ('section-id-here', 'pl.u-id3', 'url3', 'url3', 'text3', 'title3', 'curator3', 'desc3', 3);

-- Update all playlists in a section
UPDATE featured_playlists
SET is_visible = true
WHERE section_id = 'YOUR_SECTION_ID';

-- =====================================================
-- 10. USEFUL QUERIES FOR DEBUGGING
-- =====================================================

-- Count items per section
SELECT 
    cs.title as section_title,
    COUNT(fp.id) as playlist_count,
    COUNT(fa.id) as album_count
FROM content_sections cs
LEFT JOIN featured_playlists fp ON cs.id = fp.section_id
LEFT JOIN featured_albums fa ON cs.id = fa.section_id
GROUP BY cs.id, cs.title;

-- Find playlists with missing images
SELECT apple_playlist_id, custom_title
FROM featured_playlists
WHERE cover_image_url IS NULL OR instrument_image_url IS NULL;

-- Get recently updated content
SELECT 
    'playlist' as type,
    custom_title as title,
    updated_at
FROM featured_playlists
UNION ALL
SELECT 
    'album' as type,
    custom_title as title,
    updated_at
FROM featured_albums
ORDER BY updated_at DESC
LIMIT 10;

-- Check what's visible in the app
SELECT 
    cs.title as section,
    fp.custom_title as playlist_title,
    fp.display_order,
    fp.is_visible
FROM content_sections cs
JOIN featured_playlists fp ON cs.id = fp.section_id
WHERE cs.is_visible = true
ORDER BY cs.display_order, fp.display_order;

-- =====================================================
-- 11. RESET DATA (USE WITH CAUTION!)
-- =====================================================

-- Delete all content (keeps schema)
TRUNCATE TABLE featured_playlists CASCADE;
TRUNCATE TABLE featured_albums CASCADE;
TRUNCATE TABLE content_sections CASCADE;

-- Then re-run the seed data from the migration file

-- =====================================================
-- END OF QUICK REFERENCE
-- =====================================================

