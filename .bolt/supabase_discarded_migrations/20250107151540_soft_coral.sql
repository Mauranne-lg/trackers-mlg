/*
  # Création des tables pour l'application de tracking

  1. Nouvelles Tables
    - `trackers`
      - `id` (uuid, clé primaire)
      - `name` (text, non null)
      - `created_at` (timestamptz, non null)
      - `user_id` (uuid, non null, référence auth.users)
    - `events`
      - `id` (uuid, clé primaire)
      - `tracker_id` (uuid, non null, référence trackers)
      - `created_at` (timestamptz, non null)
      - `user_id` (uuid, non null, référence auth.users)

  2. Sécurité
    - RLS activé sur les deux tables
    - Politiques pour permettre aux utilisateurs de gérer leurs propres données
*/

-- Création de la table trackers
CREATE TABLE trackers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid NOT NULL REFERENCES auth.users(id)
);

-- Création de la table events
CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tracker_id uuid NOT NULL REFERENCES trackers(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid NOT NULL REFERENCES auth.users(id)
);

-- Activation de la RLS
ALTER TABLE trackers ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Politiques pour trackers
CREATE POLICY "Users can view their own trackers"
  ON trackers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own trackers"
  ON trackers
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Politiques pour events
CREATE POLICY "Users can view their own events"
  ON events
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own events"
  ON events
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);