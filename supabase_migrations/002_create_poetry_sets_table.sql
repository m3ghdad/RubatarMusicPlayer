-- Create poetry_sets table for dynamic Persian poetry overlays
CREATE TABLE IF NOT EXISTS poetry_sets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    playlist_id TEXT NOT NULL,
    text1 TEXT NOT NULL,
    text2 TEXT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient playlist lookups
CREATE INDEX IF NOT EXISTS idx_poetry_sets_playlist_id ON poetry_sets(playlist_id);

-- Create index for ordering
CREATE INDEX IF NOT EXISTS idx_poetry_sets_playlist_order ON poetry_sets(playlist_id, display_order);

-- Insert poetry sets for Setaar playlist (pl.u-vEe5t44Rjbm)
INSERT INTO poetry_sets (playlist_id, text1, text2, display_order) VALUES
('pl.u-vEe5t44Rjbm', 'دلا بسوز که سوز تو کارها بکند', 'نیاز نیم‌شب‌ات آب در جگرها کند', 1),
('pl.u-vEe5t44Rjbm', 'ما ز آغاز و ز انجام جهان بی‌خبریم', 'ول و آخر این کهنه کتاب افتادست', 2),
('pl.u-vEe5t44Rjbm', 'جهان سر به سر حکمت و عبرت است', 'چرا بهره ما همه غفلت است', 3),
('pl.u-vEe5t44Rjbm', 'ای تو ز خوبی خویش آینه را مشتری', 'سوخته باد آینه تا تو در او ننگری', 4),
('pl.u-vEe5t44Rjbm', 'این کوزه چو من عاشقِ زاری بوده‌ست', 'در بندِ سرِ زلفِ نگاری بوده‌ست', 5);

-- Insert poetry sets for Santoor playlist (pl.u-AqK9HDDXK5a)
INSERT INTO poetry_sets (playlist_id, text1, text2, display_order) VALUES
('pl.u-AqK9HDDXK5a', 'مزرعِ سبزِ فلک دیدم و داسِ مه نو', 'یادم از کِشتهٔ خویش آمد و هنگامِ درو', 1),
('pl.u-AqK9HDDXK5a', 'ترکیبِ پیاله‌ای که در هم پیوست', 'بشکستنِ آن روا نمی‌دارد مست', 2),
('pl.u-AqK9HDDXK5a', 'ر چند که سرخ روست اطراف شفق', 'شهمات همی شوند رخ زرد ترا', 3),
('pl.u-AqK9HDDXK5a', 'از هر که وجود صبر بتوانم کرد', 'الا ز وجودت که وجودم همه اوست', 4),
('pl.u-AqK9HDDXK5a', 'غم گرد دل پر هنران می‌گردد', 'شادی همه بر بی‌خبران می‌گردد', 5);

-- Insert poetry sets for Kamancheh playlist (pl.u-bvj8T00GXMg)
INSERT INTO poetry_sets (playlist_id, text1, text2, display_order) VALUES
('pl.u-bvj8T00GXMg', 'گر بر رگ جان ز شستت آید تیرم', 'چه خوشتر ازان که پیش دستت میرم', 1),
('pl.u-bvj8T00GXMg', 'بر چرخ فلک هیچ کسی چیر نشد', 'وز خوردن آدمی زمین سیر نشد', 2),
('pl.u-bvj8T00GXMg', 'آن روح که بسته بود در نقش صفات', 'از پرتو مصطفی درآمد بر ذات', 3),
('pl.u-bvj8T00GXMg', 'عشقِ رخِ یار، بر منِ زار مگیر', 'بر خسته‌دلانِ رندِ خَمّار مگیر', 4),
('pl.u-bvj8T00GXMg', 'ای دست جفای تو چو زلف تو دراز', 'وی بی‌سببی گرفته پای از من باز', 5);

-- Insert default poetry sets (for when no playlist is selected)
INSERT INTO poetry_sets (playlist_id, text1, text2, display_order) VALUES
('default', 'دلا بسوز که سوز تو کارها بکند', 'نیاز نیم‌شب‌ات آب در جگرها کند', 1),
('default', 'ما ز آغاز و ز انجام جهان بی‌خبریم', 'ول و آخر این کهنه کتاب افتادست', 2),
('default', 'جهان سر به سر حکمت و عبرت است', 'چرا بهره ما همه غفلت است', 3),
('default', 'ای تو ز خوبی خویش آینه را مشتری', 'سوخته باد آینه تا تو در او ننگری', 4),
('default', 'این کوزه چو من عاشقِ زاری بوده‌ست', 'در بندِ سرِ زلفِ نگاری بوده‌ست', 5);
