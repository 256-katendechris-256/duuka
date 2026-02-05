-- ============================================
-- DUUKA DATABASE MIGRATION V4
-- ============================================
-- Purpose:
-- - Allow owners/managers to insert and view invited users
--   (for syncing local-only team members)
-- ============================================

-- Allow owners/managers to insert invited users
DROP POLICY IF EXISTS "Owners can insert invited users" ON users;
CREATE OR REPLACE FUNCTION get_user_id_unrestricted()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT id FROM users WHERE auth_id = auth.uid()
$$;

CREATE POLICY "Owners can insert invited users"
    ON users FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM invitations i
            WHERE i.phone = users.phone
              AND i.invited_by = get_user_id_unrestricted()
              AND i.status IN ('pending', 'accepted')
        )
    );

-- Allow owners/managers to view invited users by phone
DROP POLICY IF EXISTS "Owners can view invited users" ON users;
CREATE POLICY "Owners can view invited users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM invitations i
            WHERE i.phone = users.phone
              AND i.invited_by = get_user_id_unrestricted()
              AND i.status IN ('pending', 'accepted')
        )
    );

-- Ensure team member policies can be re-run safely
DROP POLICY IF EXISTS "Owners can insert team members" ON team_members;
CREATE POLICY "Owners can insert team members"
    ON team_members FOR INSERT
    WITH CHECK (
        is_business_owner(business_id)
        OR get_user_role(business_id) = 'manager'
    );
