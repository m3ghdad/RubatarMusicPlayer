-- =====================================================
-- Rubatar App - Content Management System
-- Migration: 001 - Create Content Management Schema
-- =====================================================
-- This migration creates tables for managing playlists,
-- albums, and content sections dynamically via Supabase
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CONTENT SECTIONS TABLE
-- =====================================================
-- Defines sections that group content (e.g., "Featured Albums", "Playlists by Instrument")
CREATE TABLE IF NOT EXISTS content_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL CHECK (type IN ('playlists', 'albums')),
    title TEXT NOT NULL, -- e.g., "Featured Albums", "Playlists by instrument"
    display_order INTEGER NOT NULL DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for faster queries
CREATE INDEX idx_content_sections_type ON content_sections(type);
CREATE INDEX idx_content_sections_display_order ON content_sections(display_order);

-- Add comment
COMMENT ON TABLE content_sections IS 'Defines content sections that appear in the app';

-- =====================================================
-- 2. FEATURED PLAYLISTS TABLE
-- =====================================================
-- Stores playlist information with custom images and metadata
CREATE TABLE IF NOT EXISTS featured_playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id UUID REFERENCES content_sections(id) ON DELETE CASCADE,
    
    -- Apple Music Info
    apple_playlist_id TEXT NOT NULL UNIQUE, -- e.g., "pl.u-vEe5t44Rjbm"
    
    -- Custom Images (stored in Supabase Storage)
    cover_image_url TEXT NOT NULL, -- Main playlist cover (e.g., "Setaar", "Santoor", "Kamancheh")
    instrument_image_url TEXT, -- Footer instrument image (e.g., "SetaarInstrument")
    
    -- Custom Text
    footer_text TEXT NOT NULL, -- e.g., "Se Tār | سه تار"
    custom_title TEXT, -- Optional: Override playlist title from Apple Music
    custom_curator TEXT, -- Optional: Override curator name
    custom_description TEXT, -- Optional: Override description
    
    -- Display
    display_order INTEGER NOT NULL DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX idx_featured_playlists_section ON featured_playlists(section_id);
CREATE INDEX idx_featured_playlists_display_order ON featured_playlists(display_order);
CREATE INDEX idx_featured_playlists_visible ON featured_playlists(is_visible);

-- Add comment
COMMENT ON TABLE featured_playlists IS 'Featured playlists with custom images and metadata';

-- =====================================================
-- 3. FEATURED ALBUMS TABLE
-- =====================================================
-- Stores album information from Apple Music
CREATE TABLE IF NOT EXISTS featured_albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id UUID REFERENCES content_sections(id) ON DELETE CASCADE,
    
    -- Apple Music Info
    apple_album_url TEXT NOT NULL, -- Full Apple Music URL
    apple_album_id TEXT, -- Extracted album ID (optional, for easier querying)
    
    -- Optional Custom Data
    custom_title TEXT, -- Optional: Override album title
    custom_artist TEXT, -- Optional: Override artist name
    custom_image_url TEXT, -- Optional: Custom album cover (otherwise use Apple Music artwork)
    
    -- Display
    display_order INTEGER NOT NULL DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX idx_featured_albums_section ON featured_albums(section_id);
CREATE INDEX idx_featured_albums_display_order ON featured_albums(display_order);
CREATE INDEX idx_featured_albums_visible ON featured_albums(is_visible);

-- Add comment
COMMENT ON TABLE featured_albums IS 'Featured albums from Apple Music';

-- =====================================================
-- 4. AUTOMATIC UPDATED_AT TRIGGER
-- =====================================================
-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
CREATE TRIGGER update_content_sections_updated_at
    BEFORE UPDATE ON content_sections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_featured_playlists_updated_at
    BEFORE UPDATE ON featured_playlists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_featured_albums_updated_at
    BEFORE UPDATE ON featured_albums
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- Enable RLS on all tables
ALTER TABLE content_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE featured_playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE featured_albums ENABLE ROW LEVEL SECURITY;

-- Allow public read access (anyone can view content)
CREATE POLICY "Allow public read access to content_sections"
    ON content_sections FOR SELECT
    USING (true);

CREATE POLICY "Allow public read access to featured_playlists"
    ON featured_playlists FOR SELECT
    USING (true);

CREATE POLICY "Allow public read access to featured_albums"
    ON featured_albums FOR SELECT
    USING (true);

-- Allow authenticated users to insert/update/delete (for admin panel)
CREATE POLICY "Allow authenticated insert on content_sections"
    ON content_sections FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated update on content_sections"
    ON content_sections FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated delete on content_sections"
    ON content_sections FOR DELETE
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated insert on featured_playlists"
    ON featured_playlists FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated update on featured_playlists"
    ON featured_playlists FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated delete on featured_playlists"
    ON featured_playlists FOR DELETE
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated insert on featured_albums"
    ON featured_albums FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated update on featured_albums"
    ON featured_albums FOR UPDATE
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated delete on featured_albums"
    ON featured_albums FOR DELETE
    TO authenticated
    USING (true);

-- =====================================================
-- 6. SEED DATA (Initial Content)
-- =====================================================
-- Insert initial content sections
INSERT INTO content_sections (type, title, display_order) VALUES
    ('playlists', 'Playlists by instrument', 1),
    ('albums', 'Featured Albums', 2);

-- Get section IDs for foreign key references
DO $$
DECLARE
    playlists_section_id UUID;
    albums_section_id UUID;
BEGIN
    -- Get playlist section ID
    SELECT id INTO playlists_section_id FROM content_sections WHERE type = 'playlists' LIMIT 1;
    -- Get albums section ID
    SELECT id INTO albums_section_id FROM content_sections WHERE type = 'albums' LIMIT 1;

    -- Insert initial playlists
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
    ) VALUES
        (
            playlists_section_id,
            'pl.u-vEe5t44Rjbm',
            'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/setaar.jpg',
            'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/setaar-instrument.jpg',
            'Se Tār | سه تار',
            'The Dance of Silence | رقص سکوت',
            'Se Tār | سه تار',
            'A meditative journey where the سه‌تار (Se Tār) weaves joy and silence into one graceful breath.',
            1
        ),
        (
            playlists_section_id,
            'pl.u-AqK9HDDXK5a',
            'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/santoor.jpg',
            'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/santoor-instrument.jpg',
            'Santoor | سنتور',
            'Melody of Water | نغمه آب',
            'Santoor | سنتور',
            'A tranquil reflection where the سنتور (Santoor) speaks in ripples of light, echoing thought and memory into still air.',
            2
        ),
        (
            playlists_section_id,
            'pl.u-bvj8T00GXMg',
            'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/playlist-covers/kamancheh.jpg',
            'https://pspybykovwrfdxpkjpzd.supabase.co/storage/v1/object/public/instrument-images/kamancheh-instrument.jpg',
            'Kamancheh | کمانچه',
            'The Shadow of Time | سایه زمان',
            'Kamancheh | کمانچه',
            'A reflective journey where the کمانچه (Kamancheh) sings of seasons, distance, and the gentle passing of time.',
            3
        );
END $$;

-- =====================================================
-- 7. HELPFUL VIEWS
-- =====================================================
-- View to get all visible content with related data
CREATE OR REPLACE VIEW v_app_content AS
SELECT 
    cs.id as section_id,
    cs.type,
    cs.title as section_title,
    cs.display_order as section_order,
    
    -- Playlist data (if applicable)
    fp.id as playlist_id,
    fp.apple_playlist_id,
    fp.cover_image_url as playlist_cover,
    fp.instrument_image_url,
    fp.footer_text,
    fp.custom_title as playlist_title,
    fp.custom_curator as playlist_curator,
    fp.custom_description as playlist_description,
    fp.display_order as playlist_order,
    
    -- Album data (if applicable)
    fa.id as album_id,
    fa.apple_album_url,
    fa.apple_album_id,
    fa.custom_title as album_title,
    fa.custom_artist as album_artist,
    fa.custom_image_url as album_cover,
    fa.display_order as album_order

FROM content_sections cs
LEFT JOIN featured_playlists fp ON cs.id = fp.section_id AND fp.is_visible = true
LEFT JOIN featured_albums fa ON cs.id = fa.section_id AND fa.is_visible = true
WHERE cs.is_visible = true
ORDER BY cs.display_order, fp.display_order, fa.display_order;

COMMENT ON VIEW v_app_content IS 'Consolidated view of all visible app content';

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Next steps:
-- 1. Run this migration in Supabase SQL Editor
-- 2. Create Storage buckets: 'playlist-covers', 'instrument-images'
-- 3. Upload your images to the buckets
-- 4. Update image URLs in the seed data above
-- =====================================================

