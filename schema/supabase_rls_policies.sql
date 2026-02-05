-- ============================================
-- DUUKA ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
-- Run this AFTER supabase_schema.sql
-- ============================================

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_returns ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTION: Get user's ID from auth
-- ============================================
CREATE OR REPLACE FUNCTION get_user_id()
RETURNS UUID AS $$
    SELECT id FROM users WHERE auth_id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER;

-- Bypass RLS for user lookup inside users policies
CREATE OR REPLACE FUNCTION get_user_id_unrestricted()
RETURNS UUID
LANGUAGE SQL
SECURITY DEFINER
SET row_security = off
AS $$
    SELECT id FROM users WHERE auth_id = auth.uid()
$$;

-- ============================================
-- HELPER FUNCTION: Get user's business IDs
-- Uses get_user_id_unrestricted() to avoid recursion
-- ============================================
CREATE OR REPLACE FUNCTION get_user_business_ids()
RETURNS SETOF UUID AS $$
    SELECT business_id FROM team_members
    WHERE user_id = get_user_id_unrestricted() AND is_active = true
    UNION
    SELECT id FROM businesses
    WHERE owner_id = get_user_id_unrestricted() AND is_active = true
$$ LANGUAGE SQL SECURITY DEFINER;

-- ============================================
-- HELPER FUNCTION: Check if user is business owner
-- Uses get_user_id_unrestricted() to avoid recursion
-- ============================================
CREATE OR REPLACE FUNCTION is_business_owner(business_uuid UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM businesses
        WHERE id = business_uuid AND owner_id = get_user_id_unrestricted()
    )
$$ LANGUAGE SQL SECURITY DEFINER;

-- ============================================
-- HELPER FUNCTION: Get user's role in business
-- Uses get_user_id_unrestricted() to avoid recursion
-- ============================================
CREATE OR REPLACE FUNCTION get_user_role(bus_id UUID)
RETURNS VARCHAR AS $$
    SELECT COALESCE(
        (SELECT 'owner' FROM businesses WHERE id = bus_id AND owner_id = get_user_id_unrestricted()),
        (SELECT role FROM team_members WHERE business_id = bus_id AND user_id = get_user_id_unrestricted() AND is_active = true)
    )
$$ LANGUAGE SQL SECURITY DEFINER;

-- ============================================
-- 1. USERS POLICIES
-- ============================================
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth_id = auth.uid());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth_id = auth.uid());

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth_id = auth.uid());

-- Owners/managers can insert invited users (local-only team members)
DROP POLICY IF EXISTS "Owners can insert invited users" ON users;
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

-- Owners/managers can view invited users by phone
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

-- Users can view team members in their business
CREATE POLICY "Users can view business team members"
    ON users FOR SELECT
    USING (
        id IN (
            SELECT user_id FROM team_members
            WHERE business_id IN (SELECT get_user_business_ids())
        )
    );

-- ============================================
-- 2. BUSINESSES POLICIES
-- ============================================
-- Owners can do everything with their business
CREATE POLICY "Owners have full access to their business"
    ON businesses FOR ALL
    USING (owner_id = get_user_id());

-- Team members can view their business
CREATE POLICY "Team members can view their business"
    ON businesses FOR SELECT
    USING (id IN (SELECT get_user_business_ids()));

-- ============================================
-- 3. BRANCHES POLICIES
-- ============================================
-- Business owners can manage all branches
CREATE POLICY "Owners can manage branches"
    ON branches FOR ALL
    USING (is_business_owner(business_id));

-- Team members can view branches they belong to
CREATE POLICY "Team members can view their branches"
    ON branches FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- ============================================
-- 4. TEAM MEMBERS POLICIES
-- ============================================
-- Owners can manage all team members
CREATE POLICY "Owners can manage team members"
    ON team_members FOR ALL
    USING (is_business_owner(business_id));

-- Managers can view team in their branch
CREATE POLICY "Managers can view branch team"
    ON team_members FOR SELECT
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) = 'manager'
        )
    );

-- Users can view their own membership
CREATE POLICY "Users can view own membership"
    ON team_members FOR SELECT
    USING (user_id = get_user_id());

-- ============================================
-- 5. DEVICES POLICIES
-- ============================================
-- Users can manage their own devices
CREATE POLICY "Users can manage own devices"
    ON devices FOR ALL
    USING (user_id = get_user_id());

-- Owners can view all devices in their business
CREATE POLICY "Owners can view business devices"
    ON devices FOR SELECT
    USING (is_business_owner(business_id));

-- Owners can approve/deactivate devices
CREATE POLICY "Owners can manage business devices"
    ON devices FOR UPDATE
    USING (is_business_owner(business_id));

-- ============================================
-- 6. INVITATIONS POLICIES
-- ============================================
-- Owners and managers can create invitations
CREATE POLICY "Owners can manage invitations"
    ON invitations FOR ALL
    USING (is_business_owner(business_id));

-- Invited users can view their invitations
CREATE POLICY "Invited users can view invitations"
    ON invitations FOR SELECT
    USING (phone = (SELECT phone FROM users WHERE auth_id = auth.uid()));

-- Invited users can accept/reject
CREATE POLICY "Invited users can update invitations"
    ON invitations FOR UPDATE
    USING (phone = (SELECT phone FROM users WHERE auth_id = auth.uid()));

-- ============================================
-- 7. PRODUCTS POLICIES
-- ============================================
-- Team members can view products
CREATE POLICY "Team can view products"
    ON products FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- Owners and managers can manage products
CREATE POLICY "Owners and managers can manage products"
    ON products FOR ALL
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) IN ('owner', 'manager')
        )
    );

-- ============================================
-- 8. CUSTOMERS POLICIES
-- ============================================
-- Team members can view customers
CREATE POLICY "Team can view customers"
    ON customers FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- Owners and managers can manage customers
CREATE POLICY "Owners and managers can manage customers"
    ON customers FOR ALL
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) IN ('owner', 'manager')
        )
    );

-- ============================================
-- 9. SALES POLICIES
-- ============================================
-- Team members can create sales
CREATE POLICY "Team can create sales"
    ON sales FOR INSERT
    WITH CHECK (business_id IN (SELECT get_user_business_ids()));

-- Team members can view sales (with restrictions based on role)
CREATE POLICY "Team can view sales"
    ON sales FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- Owners can manage all sales
CREATE POLICY "Owners can manage sales"
    ON sales FOR ALL
    USING (is_business_owner(business_id));

-- ============================================
-- 10. SALE ITEMS POLICIES
-- ============================================
-- Team can insert sale items
CREATE POLICY "Team can create sale items"
    ON sale_items FOR INSERT
    WITH CHECK (
        sale_id IN (
            SELECT id FROM sales
            WHERE business_id IN (SELECT get_user_business_ids())
        )
    );

-- Team can view sale items
CREATE POLICY "Team can view sale items"
    ON sale_items FOR SELECT
    USING (
        sale_id IN (
            SELECT id FROM sales
            WHERE business_id IN (SELECT get_user_business_ids())
        )
    );

-- ============================================
-- 11. CREDIT TRANSACTIONS POLICIES
-- ============================================
-- Owners and managers can manage credit
CREATE POLICY "Owners and managers can manage credit"
    ON credit_transactions FOR ALL
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) IN ('owner', 'manager')
        )
    );

-- ============================================
-- 12. CREDIT PAYMENTS POLICIES
-- ============================================
-- Owners and managers can manage credit payments
CREATE POLICY "Owners and managers can manage credit payments"
    ON credit_payments FOR ALL
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) IN ('owner', 'manager')
        )
    );

-- ============================================
-- 13. EXPENSES POLICIES
-- ============================================
-- Owners and managers can manage expenses
CREATE POLICY "Owners and managers can manage expenses"
    ON expenses FOR ALL
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) IN ('owner', 'manager')
        )
    );

-- ============================================
-- 14. PRODUCT RETURNS POLICIES
-- ============================================
-- Owners and managers can manage returns
CREATE POLICY "Owners and managers can manage returns"
    ON product_returns FOR ALL
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) IN ('owner', 'manager')
        )
    );

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'Row Level Security policies created successfully!' AS message;
