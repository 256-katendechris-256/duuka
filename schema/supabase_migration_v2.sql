-- ============================================
-- DUUKA DATABASE MIGRATION V2
-- ============================================
-- This migration adds:
-- 1. Invitation code support for team management
-- 2. Credit transaction type and hire purchase fields
-- 3. Invoice tables with payments
-- 4. RLS policies for new tables
-- ============================================
-- Run this in Supabase SQL Editor (SQL Editor > New Query)
-- This migration is safe to run on existing databases
-- ============================================

-- ============================================
-- 1. UPDATE INVITATIONS TABLE
-- ============================================
-- Add code column for 6-digit invitation codes
ALTER TABLE invitations ADD COLUMN IF NOT EXISTS code VARCHAR(10);

-- Create index for fast code lookup
CREATE INDEX IF NOT EXISTS idx_invitations_code ON invitations(code) WHERE code IS NOT NULL;

-- ============================================
-- 2. UPDATE CREDIT_TRANSACTIONS TABLE
-- ============================================
-- Add type field to distinguish credit vs hire purchase
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS type VARCHAR(20) DEFAULT 'credit';

-- Add status field for tracking payment progress
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending';

-- Add total_amount for hire purchase tracking (renamed from amount for clarity)
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS total_amount DECIMAL(15, 2);

-- Add amount_paid to track payments made
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(15, 2) DEFAULT 0;

-- Add hire purchase product fields
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products(id) ON DELETE SET NULL;
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS product_name VARCHAR(200);
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS product_quantity INTEGER;

-- Add timestamps for cleared and collected
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS cleared_at TIMESTAMPTZ;
ALTER TABLE credit_transactions ADD COLUMN IF NOT EXISTS collected_at TIMESTAMPTZ;

-- Add indexes for status and type queries
CREATE INDEX IF NOT EXISTS idx_credit_transactions_status ON credit_transactions(status);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_type ON credit_transactions(type);

-- ============================================
-- 3. CREATE INVOICES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id),

    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',

    subtotal DECIMAL(15, 2) DEFAULT 0,
    discount DECIMAL(15, 2) DEFAULT 0,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) DEFAULT 0,
    amount_paid DECIMAL(15, 2) DEFAULT 0,
    balance DECIMAL(15, 2) DEFAULT 0,

    customer_name VARCHAR(200),
    customer_phone VARCHAR(20),
    user_name VARCHAR(100),

    notes TEXT,

    issued_at TIMESTAMPTZ DEFAULT NOW(),
    due_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    converted_to_sale_at TIMESTAMPTZ,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for invoices
CREATE INDEX IF NOT EXISTS idx_invoices_business ON invoices(business_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_user ON invoices(user_id);

-- ============================================
-- 4. CREATE INVOICE_ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,

    product_name VARCHAR(200) NOT NULL,
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    cost_price DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,
    unit VARCHAR(50) DEFAULT 'pcs',
    is_measurable BOOLEAN DEFAULT false,
    specifications JSONB DEFAULT '[]'::jsonb,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for invoice items
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_product ON invoice_items(product_id);

-- ============================================
-- 5. CREATE INVOICE_PAYMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS invoice_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),

    amount DECIMAL(15, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'cash',
    reference VARCHAR(100),
    notes TEXT,

    paid_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for invoice payments
CREATE INDEX IF NOT EXISTS idx_invoice_payments_invoice ON invoice_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_payments_business ON invoice_payments(business_id);

-- ============================================
-- 6. ENABLE RLS ON NEW TABLES
-- ============================================
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_payments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7. HELPER FUNCTIONS FOR RLS
-- ============================================
-- Function to get all business IDs the current user has access to
CREATE OR REPLACE FUNCTION get_user_business_ids()
RETURNS SETOF UUID AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT b.id
    FROM businesses b
    LEFT JOIN team_members tm ON tm.business_id = b.id
    LEFT JOIN users u ON (u.id = b.owner_id OR u.id = tm.user_id)
    WHERE u.auth_id = auth.uid()
      AND (tm.is_active = true OR b.owner_id = u.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is business owner
CREATE OR REPLACE FUNCTION is_business_owner(business_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM businesses b
        JOIN users u ON u.id = b.owner_id
        WHERE b.id = business_uuid
          AND u.auth_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's role in a business
CREATE OR REPLACE FUNCTION get_user_role(bus_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    user_role VARCHAR;
BEGIN
    -- Check if owner first
    IF is_business_owner(bus_id) THEN
        RETURN 'owner';
    END IF;

    -- Check team_members table
    SELECT tm.role INTO user_role
    FROM team_members tm
    JOIN users u ON u.id = tm.user_id
    WHERE tm.business_id = bus_id
      AND u.auth_id = auth.uid()
      AND tm.is_active = true;

    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. RLS POLICIES FOR INVOICES
-- ============================================
-- Drop existing policies if they exist (for re-running migration)
DROP POLICY IF EXISTS "Team can view invoices" ON invoices;
DROP POLICY IF EXISTS "Team can create invoices" ON invoices;
DROP POLICY IF EXISTS "Team can update invoices" ON invoices;
DROP POLICY IF EXISTS "Owners and managers can delete invoices" ON invoices;

-- View: Team members can view invoices for their business
CREATE POLICY "Team can view invoices"
    ON invoices FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- Create: Team members can create invoices for their business
CREATE POLICY "Team can create invoices"
    ON invoices FOR INSERT
    WITH CHECK (business_id IN (SELECT get_user_business_ids()));

-- Update: Team members can update invoices for their business
CREATE POLICY "Team can update invoices"
    ON invoices FOR UPDATE
    USING (business_id IN (SELECT get_user_business_ids()));

-- Delete: Only owners can delete invoices
CREATE POLICY "Owners and managers can delete invoices"
    ON invoices FOR DELETE
    USING (
        business_id IN (SELECT get_user_business_ids())
        AND (
            is_business_owner(business_id)
            OR get_user_role(business_id) = 'manager'
        )
    );

-- ============================================
-- 9. RLS POLICIES FOR INVOICE_ITEMS
-- ============================================
DROP POLICY IF EXISTS "Team can view invoice items" ON invoice_items;
DROP POLICY IF EXISTS "Team can create invoice items" ON invoice_items;
DROP POLICY IF EXISTS "Team can update invoice items" ON invoice_items;
DROP POLICY IF EXISTS "Team can delete invoice items" ON invoice_items;

-- View: Access through invoice
CREATE POLICY "Team can view invoice items"
    ON invoice_items FOR SELECT
    USING (invoice_id IN (
        SELECT id FROM invoices WHERE business_id IN (SELECT get_user_business_ids())
    ));

-- Create: Access through invoice
CREATE POLICY "Team can create invoice items"
    ON invoice_items FOR INSERT
    WITH CHECK (invoice_id IN (
        SELECT id FROM invoices WHERE business_id IN (SELECT get_user_business_ids())
    ));

-- Update: Access through invoice
CREATE POLICY "Team can update invoice items"
    ON invoice_items FOR UPDATE
    USING (invoice_id IN (
        SELECT id FROM invoices WHERE business_id IN (SELECT get_user_business_ids())
    ));

-- Delete: Access through invoice
CREATE POLICY "Team can delete invoice items"
    ON invoice_items FOR DELETE
    USING (invoice_id IN (
        SELECT id FROM invoices WHERE business_id IN (SELECT get_user_business_ids())
    ));

-- ============================================
-- 10. RLS POLICIES FOR INVOICE_PAYMENTS
-- ============================================
DROP POLICY IF EXISTS "Team can view invoice payments" ON invoice_payments;
DROP POLICY IF EXISTS "Team can create invoice payments" ON invoice_payments;

-- View: Team members can view payments for their business
CREATE POLICY "Team can view invoice payments"
    ON invoice_payments FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- Create: Team members can create payments for their business
CREATE POLICY "Team can create invoice payments"
    ON invoice_payments FOR INSERT
    WITH CHECK (business_id IN (SELECT get_user_business_ids()));

-- ============================================
-- 11. TRIGGERS FOR UPDATED_AT
-- ============================================
-- Trigger for invoices updated_at
DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 12. UPDATE TEAM_MEMBERS RLS POLICIES
-- ============================================
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view team members in their businesses" ON team_members;
DROP POLICY IF EXISTS "Owners can manage team members" ON team_members;
DROP POLICY IF EXISTS "Team members can view their own record" ON team_members;
DROP POLICY IF EXISTS "Owners can insert team members" ON team_members;
DROP POLICY IF EXISTS "Owners can update team members" ON team_members;
DROP POLICY IF EXISTS "Owners can delete team members" ON team_members;

-- Recreate with proper access
CREATE POLICY "Users can view team members in their businesses"
    ON team_members FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

CREATE POLICY "Owners can insert team members"
    ON team_members FOR INSERT
    WITH CHECK (
        is_business_owner(business_id)
        OR get_user_role(business_id) = 'manager'
    );

CREATE POLICY "Owners can update team members"
    ON team_members FOR UPDATE
    USING (
        is_business_owner(business_id)
        OR get_user_role(business_id) = 'manager'
    );

CREATE POLICY "Owners can delete team members"
    ON team_members FOR DELETE
    USING (is_business_owner(business_id));

-- ============================================
-- 13. UPDATE INVITATIONS RLS POLICIES
-- ============================================
DROP POLICY IF EXISTS "Users can view invitations for their business" ON invitations;
DROP POLICY IF EXISTS "Owners can create invitations" ON invitations;
DROP POLICY IF EXISTS "Users can view invitations by code" ON invitations;
DROP POLICY IF EXISTS "Users can update invitations" ON invitations;
DROP POLICY IF EXISTS "Anyone can view invitation by code" ON invitations;

-- Owners/managers can view invitations for their business
CREATE POLICY "Users can view invitations for their business"
    ON invitations FOR SELECT
    USING (business_id IN (SELECT get_user_business_ids()));

-- Anyone can view invitations by code (for accepting)
CREATE POLICY "Anyone can view invitation by code"
    ON invitations FOR SELECT
    USING (code IS NOT NULL);

-- Owners can create invitations
CREATE POLICY "Owners can create invitations"
    ON invitations FOR INSERT
    WITH CHECK (
        is_business_owner(business_id)
        OR get_user_role(business_id) IN ('owner', 'manager')
    );

-- Update invitations (for accepting)
CREATE POLICY "Users can update invitations"
    ON invitations FOR UPDATE
    USING (
        business_id IN (SELECT get_user_business_ids())
        OR code IS NOT NULL
    );

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'Duuka Migration V2 completed successfully!' AS message;
