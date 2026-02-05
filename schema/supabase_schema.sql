-- ============================================
-- DUUKA DATABASE SCHEMA FOR SUPABASE
-- ============================================
-- Run this in Supabase SQL Editor (SQL Editor > New Query)
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. USERS TABLE
-- ============================================
-- Stores user profiles (linked to Supabase Auth)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    phone VARCHAR(20) UNIQUE,
    name VARCHAR(100),
    email VARCHAR(255),
    photo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. BUSINESSES TABLE
-- ============================================
-- Business accounts (Sarah's Mini Mart)
CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    business_type VARCHAR(50) NOT NULL, -- retail, pharmacy, hardware, etc.
    business_size VARCHAR(50) DEFAULT 'starter', -- starter, small, growing, established
    owner_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    district VARCHAR(100),
    area VARCHAR(100),
    tin_number VARCHAR(50),
    logo_url TEXT,
    subscription_plan VARCHAR(50) DEFAULT 'free', -- free, starter, business, premium
    trial_ends_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. BRANCHES TABLE
-- ============================================
-- Multiple locations (Wandegeya, Kikuumi)
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    address TEXT,
    district VARCHAR(100),
    area VARCHAR(100),
    phone VARCHAR(20),
    is_main BOOLEAN DEFAULT false, -- Main/HQ branch
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. TEAM MEMBERS TABLE
-- ============================================
-- Staff assignments with roles (James as Cashier, Grace as Manager)
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'cashier', -- owner, manager, cashier, viewer

    -- Permissions (based on user story)
    can_make_sales BOOLEAN DEFAULT true,
    can_view_products BOOLEAN DEFAULT true,
    can_edit_products BOOLEAN DEFAULT false,
    can_manage_credit BOOLEAN DEFAULT false,
    can_view_reports BOOLEAN DEFAULT false,
    can_add_team BOOLEAN DEFAULT false,
    can_manage_devices BOOLEAN DEFAULT false,
    can_delete BOOLEAN DEFAULT false,

    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, business_id)
);

-- ============================================
-- 5. DEVICES TABLE
-- ============================================
-- Registered devices (Sarah's iPhone, Shop Tablet, etc.)
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL, -- Unique device identifier
    device_name VARCHAR(100),
    device_type VARCHAR(50), -- android, ios, web
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    fcm_token TEXT, -- For push notifications
    is_primary BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false, -- Owner must approve new devices
    is_active BOOLEAN DEFAULT true,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, device_id)
);

-- ============================================
-- 6. INVITATIONS TABLE
-- ============================================
-- Team member invitations (Sarah invites James)
CREATE TABLE invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone VARCHAR(20) NOT NULL, -- Phone of invited person
    code VARCHAR(10), -- 6-digit invitation code for team members to join
    member_name VARCHAR(200), -- Name of the invited team member
    gender VARCHAR(20), -- male, female, other
    age INTEGER, -- Age of the team member
    role VARCHAR(50) NOT NULL DEFAULT 'cashier',

    -- Permissions to grant
    can_make_sales BOOLEAN DEFAULT true,
    can_view_products BOOLEAN DEFAULT true,
    can_edit_products BOOLEAN DEFAULT false,
    can_manage_credit BOOLEAN DEFAULT false,
    can_view_reports BOOLEAN DEFAULT false,
    can_add_team BOOLEAN DEFAULT false,

    status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, rejected, expired
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL, -- NULL = all branches
    name VARCHAR(200) NOT NULL,
    description TEXT,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    category VARCHAR(100),
    unit VARCHAR(50) DEFAULT 'piece', -- piece, kg, litre, etc.
    buying_price DECIMAL(15, 2) DEFAULT 0,
    selling_price DECIMAL(15, 2) DEFAULT 0,
    quantity DECIMAL(15, 3) DEFAULT 0,
    min_stock_level DECIMAL(15, 3) DEFAULT 0,
    image_url TEXT,
    -- Custom specifications (user-defined key-value pairs)
    -- e.g., [{"name": "RAM", "value": "16GB"}, {"name": "Expiry Date", "value": "2025-06-30"}]
    specifications JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. CUSTOMERS TABLE
-- ============================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    credit_limit DECIMAL(15, 2) DEFAULT 0,
    credit_balance DECIMAL(15, 2) DEFAULT 0, -- Current amount owed
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. SALES TABLE
-- ============================================
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id), -- Cashier who made the sale

    sale_number VARCHAR(50), -- Auto-generated receipt number
    sale_type VARCHAR(50) DEFAULT 'cash', -- cash, credit, mixed
    subtotal DECIMAL(15, 2) DEFAULT 0,
    discount DECIMAL(15, 2) DEFAULT 0,
    tax DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) DEFAULT 0,
    amount_paid DECIMAL(15, 2) DEFAULT 0,
    change_amount DECIMAL(15, 2) DEFAULT 0,

    payment_method VARCHAR(50) DEFAULT 'cash', -- cash, mobile_money, card
    status VARCHAR(50) DEFAULT 'completed', -- pending, completed, voided
    notes TEXT,

    sold_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 10. SALE ITEMS TABLE
-- ============================================
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(200) NOT NULL, -- Snapshot at time of sale
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,
    -- Product specifications at time of sale (snapshot)
    -- e.g., [{"name": "RAM", "value": "16GB"}, {"name": "Color", "value": "Black"}]
    specifications JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 11. CREDIT TRANSACTIONS TABLE
-- ============================================
-- When credit is given (Mama Joyce buys on credit)
CREATE TABLE credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id),

    amount DECIMAL(15, 2) NOT NULL,
    balance_before DECIMAL(15, 2) DEFAULT 0,
    balance_after DECIMAL(15, 2) DEFAULT 0,
    due_date DATE,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 12. CREDIT PAYMENTS TABLE
-- ============================================
-- When credit is paid back (Mama Joyce pays UGX 30,000)
CREATE TABLE credit_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),

    amount DECIMAL(15, 2) NOT NULL,
    balance_before DECIMAL(15, 2) DEFAULT 0,
    balance_after DECIMAL(15, 2) DEFAULT 0,
    payment_method VARCHAR(50) DEFAULT 'cash',
    receipt_number VARCHAR(50),
    notes TEXT,

    paid_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 13. EXPENSES TABLE
-- ============================================
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id),

    category VARCHAR(100) NOT NULL, -- transport, utilities, supplies, salary, etc.
    description TEXT,
    amount DECIMAL(15, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'cash',
    receipt_url TEXT,

    expense_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 14. PRODUCT RETURNS TABLE
-- ============================================
CREATE TABLE product_returns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id),

    product_name VARCHAR(200) NOT NULL,
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    total_refund DECIMAL(15, 2) NOT NULL,
    reason TEXT,
    restock BOOLEAN DEFAULT true, -- Add back to inventory?

    returned_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_auth_id ON users(auth_id);

CREATE INDEX idx_businesses_owner ON businesses(owner_id);

CREATE INDEX idx_branches_business ON branches(business_id);

CREATE INDEX idx_team_members_user ON team_members(user_id);
CREATE INDEX idx_team_members_business ON team_members(business_id);
CREATE INDEX idx_team_members_branch ON team_members(branch_id);

CREATE INDEX idx_devices_user ON devices(user_id);
CREATE INDEX idx_devices_device_id ON devices(device_id);

CREATE INDEX idx_invitations_phone ON invitations(phone);
CREATE INDEX idx_invitations_business ON invitations(business_id);

CREATE INDEX idx_products_business ON products(business_id);
CREATE INDEX idx_products_branch ON products(branch_id);
CREATE INDEX idx_products_barcode ON products(barcode);

CREATE INDEX idx_customers_business ON customers(business_id);
CREATE INDEX idx_customers_phone ON customers(phone);

CREATE INDEX idx_sales_business ON sales(business_id);
CREATE INDEX idx_sales_branch ON sales(branch_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_user ON sales(user_id);
CREATE INDEX idx_sales_sold_at ON sales(sold_at);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);

CREATE INDEX idx_credit_transactions_customer ON credit_transactions(customer_id);
CREATE INDEX idx_credit_payments_customer ON credit_payments(customer_id);

CREATE INDEX idx_expenses_business ON expenses(business_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);

-- ============================================
-- TRIGGERS FOR updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_businesses_updated_at BEFORE UPDATE ON businesses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_members_updated_at BEFORE UPDATE ON team_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invitations_updated_at BEFORE UPDATE ON invitations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_updated_at BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_transactions_updated_at BEFORE UPDATE ON credit_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'Duuka database schema created successfully!' AS message;
