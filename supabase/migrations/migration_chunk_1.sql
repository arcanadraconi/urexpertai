-- URExpert Database Schema
-- Generated on 2025-06-20T15:21:17.506Z


-- ========== 0001_square_meadow.sql ==========
/*
  # Initial Schema Setup for URExpert

  1. New Tables
    - `profiles`
      - Extends auth.users with additional user information
      - Stores user role and profile data
    - `reports`
      - Stores medical utilization reports
      - Includes status tracking and content
    - `patients`
      - Stores patient information
      - Links to reports

  2. Security
    - Enable RLS on all tables
    - Set up appropriate access policies
    - Ensure data privacy and HIPAA compliance
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'reviewer', 'provider')),
  full_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mrn TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- Create reports table
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  provider_id UUID REFERENCES profiles(id) NOT NULL,
  reviewer_id UUID REFERENCES profiles(id),
  status TEXT NOT NULL CHECK (status IN ('draft', 'submitted', 'reviewed', 'approved', 'rejected')),
  content JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
-- Patients policies
CREATE POLICY "All authenticated users can view patients"
  ON patients FOR SELECT
  USING (true);
CREATE POLICY "Providers and admins can create patients"
  ON patients FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'provider')
    )
  );
-- Reports policies
CREATE POLICY "Users can view reports they are involved with"
  ON reports FOR SELECT
  USING (
    provider_id = auth.uid() OR 
    reviewer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );
CREATE POLICY "Providers can create reports"
  ON reports FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'provider'
    )
  );
CREATE POLICY "Users can update reports they own or review"
  ON reports FOR UPDATE
  USING (
    provider_id = auth.uid() OR 
    reviewer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );
-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reports_patient_id ON reports(patient_id);
CREATE INDEX IF NOT EXISTS idx_reports_provider_id ON reports(provider_id);
CREATE INDEX IF NOT EXISTS idx_reports_reviewer_id ON reports(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_patients_mrn ON patients(mrn);
-- ========== 0002_falling_truth.sql ==========
/*
  # Add Organizations and Branches Schema

  1. New Tables
    - `organizations`
      - `id` (uuid, primary key)
      - `name` (text)
      - `admin_id` (uuid)
      - `code` (text, 16-char unique)
      - `created_at` (timestamp)
    - `branches`
      - `id` (uuid, primary key)
      - `organization_id` (uuid, foreign key)
      - `name` (text)
      - `location` (text)
      - `admin_id` (uuid)
      - `created_at` (timestamp)

  2. Table Modifications
    - Add organization and branch references to existing tables
    - Update profiles table with role enum

  3. Security
    - Enable RLS
    - Add policies for organization and branch access
*/

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id),
  code TEXT UNIQUE NOT NULL CHECK (length(code) = 16),
  created_at TIMESTAMPTZ DEFAULT now()
);
-- Create branches table
CREATE TABLE IF NOT EXISTS branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  admin_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);