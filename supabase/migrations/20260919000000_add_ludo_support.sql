-- Migrasi Supabase untuk Fitur Game Ludo (Kita Story)
-- Tabel untuk menyimpan sesi & undangan bermain Ludo antar pasangan

CREATE TABLE IF NOT EXISTS ludo_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    guest_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    host_color TEXT NOT NULL DEFAULT 'green',
    guest_color TEXT NOT NULL DEFAULT 'blue',
    current_turn_color TEXT NOT NULL DEFAULT 'green',
    status TEXT NOT NULL DEFAULT 'invited', -- 'invited', 'accepted', 'rejected', 'in_progress', 'completed', 'abandoned'
    winner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    game_state JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks untuk query aktif
CREATE INDEX IF NOT EXISTS idx_ludo_matches_host_id ON ludo_matches(host_id);
CREATE INDEX IF NOT EXISTS idx_ludo_matches_guest_id ON ludo_matches(guest_id);
CREATE INDEX IF NOT EXISTS idx_ludo_matches_status ON ludo_matches(status);

-- Mengaktifkan Row Level Security (RLS)
ALTER TABLE ludo_matches ENABLE ROW LEVEL SECURITY;

-- Policy: Pemain dapat melihat match yang melibatkan dirinya
CREATE POLICY "Users can view matches they participate in"
ON ludo_matches FOR SELECT
USING (auth.uid() = host_id OR auth.uid() = guest_id);

-- Policy: Pengguna dapat membuat undangan match baru
CREATE POLICY "Users can create match invitations"
ON ludo_matches FOR INSERT
WITH CHECK (auth.uid() = host_id);

-- Policy: Kedua pemain dapat memperbarui state pertandingan
CREATE POLICY "Users can update matches they participate in"
ON ludo_matches FOR UPDATE
USING (auth.uid() = host_id OR auth.uid() = guest_id);

-- Tambahkan ludo_matches ke replikasi realtime Supabase
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND tablename = 'ludo_matches'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE ludo_matches;
  END IF;
END $$;
