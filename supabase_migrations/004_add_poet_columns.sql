-- Add new columns to poets table for enhanced biographical information
ALTER TABLE poets 
ADD COLUMN IF NOT EXISTS geographic_origin_en TEXT,
ADD COLUMN IF NOT EXISTS geographic_origin_fa TEXT,
ADD COLUMN IF NOT EXISTS languages_en TEXT,
ADD COLUMN IF NOT EXISTS languages_fa TEXT,
ADD COLUMN IF NOT EXISTS birth_place_en TEXT,
ADD COLUMN IF NOT EXISTS birth_place_fa TEXT,
ADD COLUMN IF NOT EXISTS death_place_en TEXT,
ADD COLUMN IF NOT EXISTS death_place_fa TEXT;

-- Add comments for the new columns
COMMENT ON COLUMN poets.geographic_origin_en IS 'Geographic origin of the poet in English';
COMMENT ON COLUMN poets.geographic_origin_fa IS 'Geographic origin of the poet in Farsi';
COMMENT ON COLUMN poets.languages_en IS 'Languages the poet wrote in (English)';
COMMENT ON COLUMN poets.languages_fa IS 'Languages the poet wrote in (Farsi)';
COMMENT ON COLUMN poets.birth_place_en IS 'Birth place of the poet in English';
COMMENT ON COLUMN poets.birth_place_fa IS 'Birth place of the poet in Farsi';
COMMENT ON COLUMN poets.death_place_en IS 'Death place of the poet in English';
COMMENT ON COLUMN poets.death_place_fa IS 'Death place of the poet in Farsi';
