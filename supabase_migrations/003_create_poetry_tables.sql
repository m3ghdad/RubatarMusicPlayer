-- Create Poetry Database Tables
-- This migration creates the complete poetry database schema for Rubatar Music Player

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create Topics table
CREATE TABLE IF NOT EXISTS topics (
    id SERIAL PRIMARY KEY,
    topic_en TEXT NOT NULL,
    topic_fa TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Moods table
CREATE TABLE IF NOT EXISTS moods (
    id SERIAL PRIMARY KEY,
    mood_en TEXT NOT NULL,
    mood_fa TEXT NOT NULL,
    color_hex TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Poets table
CREATE TABLE IF NOT EXISTS poets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en TEXT NOT NULL,
    name_fa TEXT NOT NULL,
    nickname_en TEXT,
    nickname_fa TEXT,
    biography_en TEXT,
    biography_fa TEXT,
    birthdate DATE,
    passingdate DATE,
    birthplace_en TEXT,
    birthplace_fa TEXT,
    era TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Poems table
CREATE TABLE IF NOT EXISTS poems (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    poet_id UUID NOT NULL REFERENCES poets(id) ON DELETE CASCADE,
    poem_name_en TEXT NOT NULL,
    poem_name_fa TEXT NOT NULL,
    poem_number INT,
    poem_content_en TEXT NOT NULL,
    poem_content_fa TEXT NOT NULL,
    tafseer_line_by_line_en JSONB,
    tafseer_line_by_line_fa JSONB,
    tafseer_en TEXT,
    tafseer_fa TEXT,
    topic_id INT REFERENCES topics(id) ON DELETE SET NULL,
    form TEXT CHECK (form IN ('Ghazal', 'Rubai', 'Qasida', 'Masnavi', 'Do-Beyti')),
    language_original TEXT DEFAULT 'Farsi',
    source_reference TEXT,
    translation_source TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Poem_Moods junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS poem_moods (
    id SERIAL PRIMARY KEY,
    poem_id UUID NOT NULL REFERENCES poems(id) ON DELETE CASCADE,
    mood_id INT NOT NULL REFERENCES moods(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poem_id, mood_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_poems_poet_id ON poems(poet_id);
CREATE INDEX IF NOT EXISTS idx_poems_topic_id ON poems(topic_id);
CREATE INDEX IF NOT EXISTS idx_poem_moods_poem_id ON poem_moods(poem_id);
CREATE INDEX IF NOT EXISTS idx_poem_moods_mood_id ON poem_moods(mood_id);
CREATE INDEX IF NOT EXISTS idx_poems_form ON poems(form);
CREATE INDEX IF NOT EXISTS idx_poets_era ON poets(era);

-- Insert default topics
INSERT INTO topics (topic_en, topic_fa, description) VALUES
('Death and immortality', 'مرگ و جاودانگی', 'Poems about mortality and eternal life'),
('Divine love and union', 'عشق الهی و اتحاد', 'Poems about spiritual love and divine connection'),
('Moral wisdom and ethics', 'حکمت اخلاقی و اخلاق', 'Poems about moral teachings and ethical guidance'),
('Fate and destiny', 'قدر و تقدیر', 'Poems about predestination and fate'),
('Knowledge and ignorance', 'دانش و نادانی', 'Poems about wisdom and learning'),
('Heroism', 'قهرمانی', 'Poems about courage and heroic deeds'),
('Beauty and illusion', 'زیبایی و توهم', 'Poems about beauty and deceptive appearances'),
('Rebellion and spiritual freedom', 'شورش و آزادی معنوی', 'Poems about spiritual rebellion and freedom'),
('Nature and renewal', 'طبیعت و تجدید', 'Poems about nature and renewal'),
('Reason and passion', 'عقل و شور', 'Poems about the conflict between reason and emotion'),
('Loneliness and exile', 'تنهایی و تبعید', 'Poems about isolation and exile'),
('Joy in imperfection', 'شادی در ناکمال', 'Poems about finding joy in imperfection'),
('Mystery and revelation', 'راز و مکاشفه', 'Poems about mystery and divine revelation'),
('Friendship and human connection', 'دوستی و ارتباط انسانی', 'Poems about friendship and human bonds'),
('Pride and downfall', 'غرور و سقوط', 'Poems about pride and its consequences'),
('Dreams and awakening', 'رویاها و بیداری', 'Poems about dreams and spiritual awakening'),
('Longing for meaning', 'اشتیاق به معنا', 'Poems about seeking meaning and purpose');

-- Insert default moods
INSERT INTO moods (mood_en, mood_fa, color_hex) VALUES
('Nature', 'طبیعت', '#4CAF50'),
('Heartbreak', 'شکست عشق', '#E91E63'),
('Wonder', 'حیرت', '#9C27B0'),
('Silence', 'سکوت', '#607D8B'),
('Calm', 'آرامش', '#2196F3'),
('Love', 'عشق', '#F44336'),
('Sorrow', 'اندوه', '#795548'),
('Joy', 'شادی', '#FF9800'),
('Dream', 'رویا', '#673AB7'),
('Peace', 'صلح', '#00BCD4'),
('Desire', 'میل', '#FF5722');

-- Add comments for documentation
COMMENT ON TABLE poets IS 'Master table of Persian poets with biographical information';
COMMENT ON TABLE poems IS 'Individual poems with content and metadata';
COMMENT ON TABLE topics IS 'Lookup table for poem topics/themes';
COMMENT ON TABLE moods IS 'Lookup table for poem moods/emotions';
COMMENT ON TABLE poem_moods IS 'Junction table linking poems to multiple moods';

-- Add triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_poets_updated_at BEFORE UPDATE ON poets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_poems_updated_at BEFORE UPDATE ON poems
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_topics_updated_at BEFORE UPDATE ON topics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_moods_updated_at BEFORE UPDATE ON moods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
