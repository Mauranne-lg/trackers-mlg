/*
  # Create tables for tracker application

  1. New Tables
    - `trackers`
      - `id` (uuid, primary key)
      - `name` (text)
      - `created_at` (timestamp with time zone)
      - `user_id` (uuid, references auth.users)
      - `fields` (jsonb array of field configurations)
    
    - `events`
      - `id` (uuid, primary key)
      - `tracker_id` (uuid, references trackers)
      - `created_at` (timestamp with time zone)
      - `user_id` (uuid, references auth.users)
      - `data` (jsonb for storing event data)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to manage their own data
*/

-- Create trackers table
CREATE TABLE IF NOT EXISTS trackers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  user_id uuid DEFAULT auth.uid() REFERENCES auth.users(id),
  fields jsonb NOT NULL
);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tracker_id uuid REFERENCES trackers(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  user_id uuid DEFAULT auth.uid() REFERENCES auth.users(id),
  data jsonb NOT NULL
);

-- Enable Row Level Security
ALTER TABLE trackers ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Policies for trackers table
CREATE POLICY "Users can create their own trackers"
  ON trackers
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own trackers"
  ON trackers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policies for events table
CREATE POLICY "Users can create events for their trackers"
  ON events
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM trackers
      WHERE id = tracker_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view events for their trackers"
  ON events
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM trackers
      WHERE id = tracker_id AND user_id = auth.uid()
    )
  );