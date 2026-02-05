-- ============================================
-- MIGRATION: Add missing columns to invitations table
-- Run this in Supabase SQL Editor
-- ============================================

-- Add invitation code column (6-digit code for team members to join)
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS code VARCHAR(10);

-- Add member details columns
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS member_name VARCHAR(200);
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS gender VARCHAR(20);
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS age INTEGER;

-- Create index for code lookup (important for invitation acceptance)
CREATE INDEX IF NOT EXISTS idx_invitations_code ON invitations(code) WHERE code IS NOT NULL;

-- Update RLS policy to allow unauthenticated reads of invitations by code
-- This is needed so team members can validate their invitation code before signing up
DROP POLICY IF EXISTS "Anyone can read invitation by code" ON invitations;
CREATE POLICY "Anyone can read invitation by code"
    ON invitations FOR SELECT
    USING (code IS NOT NULL);

-- Allow team members to update invitation status when they accept
DROP POLICY IF EXISTS "Anyone can accept invitation" ON invitations;
CREATE POLICY "Anyone can accept invitation"
    ON invitations FOR UPDATE
    USING (status = 'pending' AND code IS NOT NULL)
    WITH CHECK (status = 'accepted');

-- ============================================
-- VERIFY: Run this to check the columns exist
-- ============================================
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'invitations' ORDER BY ordinal_position;
