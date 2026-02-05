-- ============================================
-- DUUKA DATABASE MIGRATION V3
-- ============================================
-- Purpose:
-- - Allow users.phone to be NULL to support Google-only auth
-- ============================================

ALTER TABLE users
  ALTER COLUMN phone DROP NOT NULL;
