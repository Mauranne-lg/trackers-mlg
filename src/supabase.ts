import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Only create the client if we have the required environment variables
export const supabase = supabaseUrl && supabaseKey 
  ? createClient(supabaseUrl, supabaseKey, {
      auth: {
        persistSession: true, // Enable persistent sessions
        storageKey: 'tracker-auth', // Custom storage key
        autoRefreshToken: true, // Enable automatic token refresh
      },
    })
  : null

// Helper function to check if Supabase is configured
export const isSupabaseConfigured = () => {
  return !!supabase
}