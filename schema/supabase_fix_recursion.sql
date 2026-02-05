-- ============================================
-- FIX: Infinite Recursion in RLS Policies
-- ============================================
-- Run this in Supabase SQL Editor to fix the
-- "infinite recursion detected in policy for relation users" error
-- ============================================

-- 1. Ensure the unrestricted helper exists (bypasses RLS)
CREATE OR REPLACE FUNCTION get_user_id_unrestricted()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT id FROM users WHERE auth_id = auth.uid()
$$;

-- 2. Update get_user_id to also bypass RLS
CREATE OR REPLACE FUNCTION get_user_id()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT id FROM users WHERE auth_id = auth.uid()
$$;

-- 3. Helper to get user phone without RLS (for invitations policies)
CREATE OR REPLACE FUNCTION get_user_phone_unrestricted()
RETURNS VARCHAR
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT phone FROM users WHERE auth_id = auth.uid()
$$;

-- 4. Replace helper functions to use unrestricted version and bypass RLS
CREATE OR REPLACE FUNCTION get_user_business_ids()
RETURNS SETOF UUID
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT business_id FROM team_members
    WHERE user_id = get_user_id_unrestricted() AND is_active = true
    UNION
    SELECT id FROM businesses
    WHERE owner_id = get_user_id_unrestricted() AND is_active = true
$$;

CREATE OR REPLACE FUNCTION is_business_owner(business_uuid UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1 FROM businesses
        WHERE id = business_uuid AND owner_id = get_user_id_unrestricted()
    )
$$;

CREATE OR REPLACE FUNCTION get_user_role(bus_id UUID)
RETURNS VARCHAR
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT COALESCE(
        (SELECT 'owner' FROM businesses WHERE id = bus_id AND owner_id = get_user_id_unrestricted()),
        (SELECT role FROM team_members WHERE business_id = bus_id AND user_id = get_user_id_unrestricted() AND is_active = true)
    )
$$;

-- 5. Drop problematic users policy that causes recursion
DROP POLICY IF EXISTS "Users can view business team members" ON users;

-- 6. Fix invitations policies that directly query users table
DROP POLICY IF EXISTS "Invited users can view invitations" ON invitations;
DROP POLICY IF EXISTS "Invited users can update invitations" ON invitations;

CREATE POLICY "Invited users can view invitations"
    ON invitations FOR SELECT
    USING (phone = get_user_phone_unrestricted());

CREATE POLICY "Invited users can update invitations"
    ON invitations FOR UPDATE
    USING (phone = get_user_phone_unrestricted());

-- ============================================
-- Verify the fix
-- ============================================
SELECT 'Recursion fix applied successfully!' AS message;

-- Verify all functions have row_security=off
SELECT proname, prosecdef, proconfig
FROM pg_proc
WHERE proname IN ('get_user_id', 'get_user_id_unrestricted', 'get_user_phone_unrestricted',
                  'get_user_business_ids', 'is_business_owner', 'get_user_role');
