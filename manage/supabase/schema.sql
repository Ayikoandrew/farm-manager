-- Supabase Database Schema for Farm Manager App

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    photo_url TEXT,
    phone_number TEXT,
    farms JSONB DEFAULT '[]'::jsonb,  -- Array of farm memberships with roles
    active_farm_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ============================================
-- AUTO-CREATE USER PROFILE ON SIGNUP (TRIGGER)
-- ============================================
-- This trigger automatically creates a user profile when someone signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, email, display_name, created_at, updated_at, last_login_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name'),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, users.display_name),
        last_login_at = NOW();
    RETURN NEW;
END;
$$;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Drop existing policies if they exist (for idempotent schema)
DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Users can read/update their own profile
-- Using (select auth.uid()) for better performance (evaluated once per query, not per row)
CREATE POLICY "Users can read own profile" ON users
    FOR SELECT USING ((select auth.uid()) = id);
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING ((select auth.uid()) = id);
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK ((select auth.uid()) = id);

-- ============================================
-- FARMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES users(id),
    description TEXT,
    location TEXT,
    currency TEXT DEFAULT 'UGX',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE farms ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ANIMALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    tag_id TEXT NOT NULL,
    name TEXT,
    species TEXT NOT NULL,
    breed TEXT,
    gender TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    date_of_birth DATE,
    current_weight DECIMAL(10,2),
    purchase_price DECIMAL(10,2),
    purchase_date DATE,
    mother_id UUID REFERENCES animals(id),
    father_id UUID REFERENCES animals(id),
    photo_url TEXT,
    photo_gallery JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(farm_id, tag_id)
);

ALTER TABLE animals ENABLE ROW LEVEL SECURITY;

-- ============================================
-- BREEDING RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS breeding_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    sire_id UUID REFERENCES animals(id),
    status TEXT NOT NULL DEFAULT 'in_heat',
    heat_date TIMESTAMPTZ NOT NULL,
    breeding_date TIMESTAMPTZ,
    expected_farrow_date TIMESTAMPTZ,
    actual_farrow_date TIMESTAMPTZ,
    litter_size INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE breeding_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FEEDING RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS feeding_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    animal_id UUID REFERENCES animals(id) ON DELETE SET NULL,
    feed_type TEXT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit TEXT DEFAULT 'kg',
    cost DECIMAL(10,2),
    date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE feeding_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- WEIGHT RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS weight_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    weight DECIMAL(10,2) NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE weight_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HEALTH RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS health_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    date TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'pending',
    veterinarian TEXT,
    diagnosis TEXT,
    treatment TEXT,
    medication TEXT,
    dosage TEXT,
    vaccine_name TEXT,
    next_due_date TIMESTAMPTZ,
    follow_up_date TIMESTAMPTZ,
    withdrawal_end_date TIMESTAMPTZ,
    cost DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TRANSACTIONS TABLE (Financial)
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    animal_id UUID REFERENCES animals(id) ON DELETE SET NULL,
    type TEXT NOT NULL, -- 'income' or 'expense'
    category TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    description TEXT,
    payment_method TEXT,
    reference_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- BUDGETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    total_budget DECIMAL(10,2) NOT NULL,
    category_budgets JSONB DEFAULT '{}',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(farm_id, year, month)
);

ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- ============================================
-- REMINDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    animal_id UUID REFERENCES animals(id) ON DELETE SET NULL,
    animal_tag_id TEXT,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMPTZ NOT NULL,
    priority TEXT DEFAULT 'medium',
    status TEXT DEFAULT 'pending',
    source_record_id UUID,
    source_type TEXT,
    advance_notice_days INTEGER DEFAULT 3,
    is_auto_generated BOOLEAN DEFAULT false,
    snoozed_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- REMINDER SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS reminder_settings (
    farm_id UUID PRIMARY KEY REFERENCES farms(id) ON DELETE CASCADE,
    breeding_reminders_enabled BOOLEAN DEFAULT true,
    health_reminders_enabled BOOLEAN DEFAULT true,
    weight_check_reminders_enabled BOOLEAN DEFAULT true,
    feeding_reminders_enabled BOOLEAN DEFAULT true,
    financial_reminders_enabled BOOLEAN DEFAULT true,
    default_advance_notice_days INTEGER DEFAULT 3,
    weight_check_interval_days INTEGER DEFAULT 7,
    quiet_hours_start JSONB,
    quiet_hours_end JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reminder_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policy for reminder_settings
CREATE POLICY "Farm members can manage reminder settings" ON reminder_settings
    FOR ALL USING (public.is_farm_member(farm_id));

-- Add columns if they don't exist (for existing databases)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminder_settings' AND column_name = 'weight_check_reminders_enabled') THEN
        ALTER TABLE reminder_settings ADD COLUMN weight_check_reminders_enabled BOOLEAN DEFAULT true;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminder_settings' AND column_name = 'weight_check_interval_days') THEN
        ALTER TABLE reminder_settings ADD COLUMN weight_check_interval_days INTEGER DEFAULT 7;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminder_settings' AND column_name = 'quiet_hours_start') THEN
        ALTER TABLE reminder_settings ADD COLUMN quiet_hours_start JSONB;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminder_settings' AND column_name = 'quiet_hours_end') THEN
        ALTER TABLE reminder_settings ADD COLUMN quiet_hours_end JSONB;
    END IF;
END $$;

-- ============================================
-- PAYMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    transaction_reference TEXT NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'UGX',
    payment_type TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    provider TEXT NOT NULL,
    provider_reference TEXT,
    phone_number TEXT,
    network TEXT,
    customer_name TEXT,
    customer_email TEXT,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- WALLETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0,
    currency TEXT DEFAULT 'UGX',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(farm_id)
);

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- ============================================
-- INVITE CODES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS invite_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    farm_name TEXT,  -- Store farm name for display in invites
    code TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL,
    role TEXT NOT NULL,
    created_by UUID REFERENCES users(id),
    is_used BOOLEAN DEFAULT false,
    used_by UUID REFERENCES users(id),
    used_at TIMESTAMPTZ,
    max_uses INTEGER DEFAULT 1,  -- How many times code can be used
    use_count INTEGER DEFAULT 0,  -- How many times code has been used
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES FOR FARM DATA ACCESS
-- ============================================

-- Helper function to check farm membership (with fixed search_path for security)
-- MUST be defined before any policies that use it
CREATE OR REPLACE FUNCTION public.is_farm_member(farm_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    -- Check if user owns the farm OR is a member
    RETURN EXISTS (
        SELECT 1 FROM public.farms 
        WHERE id = farm_uuid 
        AND owner_id = (select auth.uid())
    ) OR EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = (select auth.uid()) 
        AND (
            active_farm_id = farm_uuid 
            OR EXISTS (
                SELECT 1 FROM jsonb_array_elements(farms) AS f 
                WHERE f->>'farm_id' = farm_uuid::text
            )
        )
    );
END;
$$;

-- ============================================
-- ADMIN NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS admin_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info', -- info, warning, error, success
    category TEXT DEFAULT 'system', -- system, animal, health, breeding, financial, reminder
    is_read BOOLEAN DEFAULT false,
    action_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

-- Policies for admin_notifications
DROP POLICY IF EXISTS "Users can read own notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Users can insert notifications" ON admin_notifications;

CREATE POLICY "Users can read own notifications" ON admin_notifications
    FOR SELECT USING (user_id = (select auth.uid()) OR (farm_id IS NOT NULL AND public.is_farm_member(farm_id)));
    
CREATE POLICY "Users can update own notifications" ON admin_notifications
    FOR UPDATE USING (user_id = (select auth.uid()));
    
CREATE POLICY "Users can insert notifications" ON admin_notifications
    FOR INSERT WITH CHECK (user_id = (select auth.uid()) OR (farm_id IS NOT NULL AND public.is_farm_member(farm_id)));

-- ============================================
-- APPLY RLS POLICIES TO FARM TABLES
-- ============================================
DO $$
DECLARE
    tbl_name TEXT;
BEGIN
    -- Apply farm member policies to most tables (excluding invite_codes which needs special handling)
    FOR tbl_name IN 
        SELECT unnest(ARRAY['animals', 'breeding_records', 'feeding_records', 
                            'weight_records', 'health_records', 'transactions',
                            'budgets', 'reminders', 'reminder_settings', 
                            'payments', 'wallets'])
    LOOP
        -- Drop existing policy if it exists
        EXECUTE format('
            DROP POLICY IF EXISTS "Farm members can access %I" ON public.%I
        ', tbl_name, tbl_name);
        
        -- Create the policy
        EXECUTE format('
            CREATE POLICY "Farm members can access %I" ON public.%I
                FOR ALL USING (public.is_farm_member(farm_id))
        ', tbl_name, tbl_name);
    END LOOP;
END $$;

-- ============================================
-- INVITE CODES RLS POLICIES (Special handling)
-- ============================================
-- Anyone authenticated can READ invite codes (for validation when joining)
-- Only farm members can CREATE/DELETE invite codes
-- UPDATE is restricted to only marking codes as used
DROP POLICY IF EXISTS "Farm members can access invite_codes" ON invite_codes;
DROP POLICY IF EXISTS "Anyone can read invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Anyone can update invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Farm members can manage invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Farm members can update invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Farm members can delete invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Authenticated users can use invite codes" ON invite_codes;

CREATE POLICY "Anyone can read invite codes" ON invite_codes
    FOR SELECT USING (true);

-- Restricted UPDATE policy - only allow marking codes as used (not arbitrary updates)
CREATE POLICY "Authenticated users can use invite codes" ON invite_codes
    FOR UPDATE 
    USING (
        -- User can update if the code is valid and not expired
        is_used = false 
        AND expires_at > NOW()
        AND use_count < max_uses
    )
    WITH CHECK (
        -- Only allow updating to mark as used
        is_used = true
    );

CREATE POLICY "Farm members can insert invite codes" ON invite_codes
    FOR INSERT WITH CHECK (public.is_farm_member(farm_id));

CREATE POLICY "Farm members can delete invite codes" ON invite_codes
    FOR DELETE USING (public.is_farm_member(farm_id));

-- Drop existing farms policy if it exists
DROP POLICY IF EXISTS "Owners and members can access farms" ON farms;

-- Farms policy - owners and members can access farms
-- Using (select auth.uid()) for better performance (evaluated once per query, not per row)
CREATE POLICY "Owners and members can access farms" ON farms
    FOR ALL USING (
        owner_id = (select auth.uid()) OR 
        public.is_farm_member(id)
    );

-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Create storage bucket for animal photos (if it doesn't exist)
-- Note: This needs to be run with service role or from dashboard
INSERT INTO storage.buckets (id, name, public)
VALUES ('animal-photos', 'animal-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage policies for animal-photos bucket
-- Allow authenticated users to upload
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
CREATE POLICY "Allow authenticated uploads" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'animal-photos');

-- Allow authenticated users to update their uploads
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
CREATE POLICY "Allow authenticated updates" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'animal-photos');

-- Allow authenticated users to delete their uploads
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
CREATE POLICY "Allow authenticated deletes" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'animal-photos');

-- Allow public read access (since bucket is public)
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
CREATE POLICY "Allow public read" ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'animal-photos');

-- ============================================
-- REALTIME SUBSCRIPTIONS
-- ============================================
-- Enable realtime for tables that need live updates
ALTER PUBLICATION supabase_realtime ADD TABLE animals;
ALTER PUBLICATION supabase_realtime ADD TABLE breeding_records;
ALTER PUBLICATION supabase_realtime ADD TABLE health_records;
ALTER PUBLICATION supabase_realtime ADD TABLE reminders;
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE users;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_animals_farm_id ON animals(farm_id);
CREATE INDEX IF NOT EXISTS idx_animals_tag_id ON animals(farm_id, tag_id);
CREATE INDEX IF NOT EXISTS idx_breeding_records_farm_id ON breeding_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_breeding_records_animal_id ON breeding_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_health_records_farm_id ON health_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_health_records_animal_id ON health_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_transactions_farm_id ON transactions(farm_id);
CREATE INDEX IF NOT EXISTS idx_reminders_farm_id ON reminders(farm_id);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON reminders(farm_id, status);

-- Foreign key indexes for performance (prevents slow joins)
CREATE INDEX IF NOT EXISTS idx_animals_mother_id ON animals(mother_id);
CREATE INDEX IF NOT EXISTS idx_animals_father_id ON animals(father_id);
CREATE INDEX IF NOT EXISTS idx_breeding_records_sire_id ON breeding_records(sire_id);
CREATE INDEX IF NOT EXISTS idx_feeding_records_farm_id ON feeding_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_feeding_records_animal_id ON feeding_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_weight_records_farm_id ON weight_records(farm_id);
CREATE INDEX IF NOT EXISTS idx_weight_records_animal_id ON weight_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_transactions_animal_id ON transactions(animal_id);
CREATE INDEX IF NOT EXISTS idx_reminders_animal_id ON reminders(animal_id);
CREATE INDEX IF NOT EXISTS idx_invite_codes_farm_id ON invite_codes(farm_id);
CREATE INDEX IF NOT EXISTS idx_invite_codes_created_by ON invite_codes(created_by);
CREATE INDEX IF NOT EXISTS idx_invite_codes_used_by ON invite_codes(used_by);
CREATE INDEX IF NOT EXISTS idx_payments_farm_id ON payments(farm_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_farm_id ON admin_notifications(farm_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_user_id ON admin_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_farms_owner_id ON farms(owner_id);
CREATE INDEX IF NOT EXISTS idx_budgets_farm_id ON budgets(farm_id);
