-- Buat tabel game_history
CREATE TABLE IF NOT EXISTS game_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    game_type TEXT NOT NULL,
    difficulty TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    partner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    duration_seconds INTEGER NOT NULL,
    score INTEGER,
    status TEXT NOT NULL, -- 'completed', 'failed', 'abandoned'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Mengaktifkan Row Level Security (RLS)
ALTER TABLE game_history ENABLE ROW LEVEL SECURITY;

-- Policy: Pengguna bisa melihat history mereka sendiri atau history pasangannya
CREATE POLICY "Users can view own and partner's game history" 
ON game_history 
FOR SELECT 
USING (
    auth.uid() = user_id OR 
    auth.uid() = partner_id
);

-- Policy: Pengguna terautentikasi bisa memasukkan data (insert)
CREATE POLICY "Users can insert their own game history" 
ON game_history 
FOR INSERT 
WITH CHECK (
    auth.uid() = user_id
);

-- Indeks untuk pencarian yang lebih cepat
CREATE INDEX IF NOT EXISTS idx_game_history_user_id ON game_history(user_id);
CREATE INDEX IF NOT EXISTS idx_game_history_game_type ON game_history(game_type);
