export interface Tracker {
  id: string
  name: string
  created_at: string
  user_id: string
  fields: TrackerField[]
}

export interface TrackerField {
  type: 'date' | 'datetime' | 'text'
  name: string
}

export interface Event {
  id: string
  tracker_id: string
  created_at: string
  user_id: string
  data: Record<string, any>
}