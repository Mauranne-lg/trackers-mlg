<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase, isSupabaseConfigured } from '../supabase'
import type { Tracker, Event } from '../types'
import { format } from 'date-fns'
import { ArrowLeftIcon, PencilIcon, TrashIcon, PencilSquareIcon } from '@heroicons/vue/24/solid'

const route = useRoute()
const router = useRouter()
const tracker = ref<Tracker | null>(null)
const events = ref<Event[]>([])
const isConfigured = ref(isSupabaseConfigured())
const textInput = ref('')
const notification = ref('')
const notificationTimeout = ref<number | null>(null)
const editingEvent = ref<Event | null>(null)
const editValue = ref('')
const showDeleteConfirm = ref(false)
const eventToDelete = ref<Event | null>(null)
const showTrackerDeleteConfirm = ref(false)
const editingTracker = ref(false)
const editTrackerName = ref('')

// Subscribe to real-time updates
const subscribeToEvents = () => {
  if (!tracker.value) return null

  const subscription = supabase!
    .channel('events-channel')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'events',
        filter: `tracker_id=eq.${tracker.value.id}`
      },
      async () => {
        await loadEvents()
      }
    )
    .subscribe()

  return () => {
    subscription.unsubscribe()
  }
}

const loadTrackerAndEvents = async () => {
  if (!isConfigured.value) return null

  const trackerId = route.params.id as string

  const { data: trackerData } = await supabase!
    .from('trackers')
    .select('*')
    .eq('id', trackerId)
    .single()

  if (trackerData) {
    tracker.value = trackerData
    await loadEvents()
    return subscribeToEvents()
  }
  return null
}

const loadEvents = async () => {
  if (!tracker.value) return

  const { data: eventsData } = await supabase!
    .from('events')
    .select('*')
    .eq('tracker_id', tracker.value.id)
    .order('created_at', { ascending: false })

  if (eventsData) events.value = eventsData
}

const showNotification = (message: string) => {
  notification.value = message
  if (notificationTimeout.value) {
    clearTimeout(notificationTimeout.value)
  }
  notificationTimeout.value = window.setTimeout(() => {
    notification.value = ''
  }, 3000)
}

const startEditEvent = (event: Event) => {
  editingEvent.value = event
  const field = tracker.value?.fields[0]
  if (field) {
    editValue.value = event.data[field.name] || ''
  }

}

const cancelEditEvent = () => {
  editingEvent.value = null
  editValue.value = ''
}

const saveEditEvent = async () => {
  if (!editingEvent.value || !tracker.value?.fields[0]) return

  const field = tracker.value.fields[0]

  const { error } = await supabase!
    .from('events')
    .update({
      data: { [field.name]: editValue.value }
    })
    .eq('id', editingEvent.value.id)

  if (!error) {
    await loadEvents()
    showNotification('Événement modifié avec succès')
    cancelEditEvent()
  }
}

const confirmDeleteEvent = (event: Event) => {
  eventToDelete.value = event
  showDeleteConfirm.value = true
}

const cancelDeleteEvent = () => {
  eventToDelete.value = null
  showDeleteConfirm.value = false
}

const saveDeleteEvent = async () => {
  if (!eventToDelete.value) return

  const { error } = await supabase!
    .from('events')
    .delete()
    .eq('id', eventToDelete.value.id)

  if (!error) {
    await loadEvents()
    showNotification('Événement supprimé avec succès')
    cancelDeleteEvent()
  }
}

const startEditTracker = () => {
  if (!tracker.value) return
  editTrackerName.value = tracker.value.name
  editingTracker.value = true
}

const cancelEditTracker = () => {
  editingTracker.value = false
  editTrackerName.value = ''
}

const saveEditTracker = async () => {
  if (!tracker.value || !editTrackerName.value) return

  const { error } = await supabase!
    .from('trackers')
    .update({ name: editTrackerName.value })
    .eq('id', tracker.value.id)

  if (!error) {
    const new_name = tracker.value.name
    showNotification('Tracker modifié avec succès')
    editingTracker.value = false
    tracker.value.name = new_name
  }
}

const confirmDeleteTracker = () => {
  showTrackerDeleteConfirm.value = true
}

const cancelDeleteTracker = () => {
  showTrackerDeleteConfirm.value = false
}

const deleteTracker = async () => {
  if (!tracker.value) return

  const { error } = await supabase!
    .from('trackers')
    .delete()
    .eq('id', tracker.value.id)

  if (!error) {
    router.push('/')
  }
}

const createEvent = async () => {
  if (!tracker.value?.fields[0]) return

  const field = tracker.value.fields[0]
  let fieldValue: string

  switch (field.type) {
    case 'date':
      fieldValue = format(new Date(), 'yyyy-MM-dd')
      break
    case 'datetime':
      fieldValue = new Date().toISOString()
      break
    case 'text':
      if (!textInput.value) return
      fieldValue = textInput.value
      break
    default:
      return
  }

  const { error } = await supabase!
    .from('events')
    .insert([
      {
        tracker_id: tracker.value.id,
        data: { [field.name]: fieldValue }
      }
    ])

  if (!error) {
    textInput.value = ''
    await loadEvents()
    showNotification('Événement ajouté avec succès')
  }
}

const goBack = () => {
  router.push('/')
}

onMounted(() => {
  if (!isConfigured.value) {
    router.push('/')
    return
  }
  const cleanup = loadTrackerAndEvents()
  if (cleanup instanceof Promise) {
    cleanup.then(unsubscribe => {
      if (typeof unsubscribe === 'function') {
        onUnmounted(unsubscribe)
      }
    })
  }
})

const formatEventValue = (event: Event) => {
  if (!tracker.value?.fields[0]) return ''

  const field = tracker.value.fields[0]
  const value = event.data[field.name]

  if (!value) return ''

  switch (field.type) {
    case 'date':
      return format(new Date(value), 'dd/MM/yyyy')
    case 'datetime':
      return format(new Date(value), 'dd/MM/yyyy HH:mm')
    default:
      return value
  }
}

const formatEventDate = (event: Event) => {
  return format(new Date(event.created_at), 'dd/MM/yyyy HH:mm')
}
</script>

<template>
  <div class="max-w-4xl mx-auto p-4">
    <button @click="goBack"
      class="mb-4 flex items-center text-amber-700 hover:text-amber-800 transition-colors focus:outline-none focus:ring-2 focus:ring-amber-500 rounded p-1"
      aria-label="Retour à la liste des trackers">
      <ArrowLeftIcon class="w-5 h-5 mr-1" aria-hidden="true" />
      <span class="text-sm md:text-base">Retour à la liste</span>
    </button>

    <!-- Notification -->
    <ouput v-if="notification" role="status" aria-live="polite"
      class="fixed bottom-4 right-4 bg-green-100 border-l-4 border-green-500 p-4 rounded shadow-lg max-w-[90vw] md:max-w-md z-50">
      <p class="text-green-700 text-sm md:text-base">{{ notification }}</p>
    </ouput>

    <!-- Delete Event Confirmation Modal -->
    <dialog v-if="showDeleteConfirm"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
      aria-labelledby="delete-modal-title">
      <div class="bg-white rounded-lg p-4 md:p-6 w-full max-w-md">
        <h2 id="delete-modal-title"
          class="text-lg md:text-xl font-bold text-amber-700 mb-4">
          Confirmer la suppression
        </h2>
        <p class="mb-6 text-gray-700">
          Êtes-vous sûr de vouloir supprimer cet événement ? Cette action est
          irréversible.
        </p>
        <div class="flex justify-end space-x-3">
          <button @click="cancelDeleteEvent"
            class="px-4 py-2 bg-gray-200 text-gray-800 rounded hover:bg-gray-300 transition-colors">
            Annuler
          </button>
          <button @click="saveDeleteEvent"
            class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors">
            Supprimer
          </button>
        </div>
      </div>
    </dialog>

    <!-- Delete Tracker Confirmation Modal -->
    <dialog v-if="showTrackerDeleteConfirm"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
      aria-labelledby="tracker-delete-modal-title">
      <div class="bg-white rounded-lg p-4 md:p-6 w-full max-w-md">
        <h2 id="tracker-delete-modal-title"
          class="text-lg md:text-xl font-bold text-amber-700 mb-4">
          Confirmer la suppression du tracker
        </h2>
        <p class="mb-6 text-gray-700">
          Êtes-vous sûr de vouloir supprimer ce tracker et tous ses événements ? Cette
          action est irréversible.
        </p>
        <div class="flex justify-end space-x-3">
          <button @click="cancelDeleteTracker"
            class="px-4 py-2 bg-gray-200 text-gray-800 rounded hover:bg-gray-300 transition-colors">
            Annuler
          </button>
          <button @click="deleteTracker"
            class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors">
            Supprimer
          </button>
        </div>
      </div>
    </dialog>

    <template v-if="tracker">
      <div class="flex justify-between items-center mb-4">
        <div v-if="!editingTracker" class="flex-1">
          <h1 class="text-2xl md:text-3xl font-bold text-amber-700">{{ tracker.name }}
          </h1>
          <p class="text-sm md:text-base text-amber-600">
            Créé le {{ format(new Date(tracker.created_at), 'dd/MM/yyyy HH:mm') }}
          </p>
        </div>
        <div v-else class="flex-1">
          <input v-model="editTrackerName" type="text"
            class="w-full p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500 text-xl font-bold"
            @keyup.enter="saveEditTracker">
        </div>
        <div class="flex space-x-2">
          <template v-if="!editingTracker">
            <button @click="startEditTracker"
              class="p-1.5 md:p-2 text-amber-600 hover:text-amber-800 transition-colors focus:outline-none focus:ring-2 focus:ring-amber-500 rounded"
              aria-label="Modifier le tracker">
              <PencilIcon class="w-5 h-5" aria-hidden="true" />
            </button>
            <button @click="confirmDeleteTracker"
              class="p-1.5 md:p-2 text-red-600 hover:text-red-800 transition-colors focus:outline-none focus:ring-2 focus:ring-red-500 rounded"
              aria-label="Supprimer le tracker">
              <TrashIcon class="w-5 h-5" aria-hidden="true" />
            </button>
          </template>
          <template v-else>
            <button @click="saveEditTracker"
              class="px-3 py-1 bg-amber-600 text-white rounded hover:bg-amber-700 transition-colors">
              Enregistrer
            </button>
            <button @click="cancelEditTracker"
              class="px-3 py-1 bg-gray-200 text-gray-800 rounded hover:bg-gray-300 transition-colors">
              Annuler
            </button>
          </template>
        </div>
      </div>

      <div class="flex justify-between items-center mb-6">
        <div class="flex-1">
          <img src="/src/assets/detail-illustration.svg" alt="Illustration"
            class="w-32 h-32 mx-auto" />
        </div>
      </div>

      <div class="bg-white p-4 md:p-6 rounded-lg shadow-md mb-6 md:mb-8">
        <div v-if="tracker.fields[0]" class="space-y-4">
          <p class="text-base md:text-lg text-amber-800">
            Type de suivi : <span
              class="font-medium">{{ tracker.fields[0].type }}</span>
          </p>

          <div v-if="tracker.fields[0].type === 'text'" class="space-y-2">
            <label :for="'text-input-' + tracker.id" class="sr-only">Entrez votre
              texte</label>
            <input :id="'text-input-' + tracker.id" v-model="textInput" type="text"
              class="w-full p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500"
              placeholder="Entrez votre texte">
          </div>

          <button @click="createEvent"
            :disabled="tracker.fields[0].type === 'text' && !textInput" :class="{
              'opacity-50 cursor-not-allowed': tracker.fields[0].type === 'text' && !textInput
            }"
            class="w-full bg-amber-600 text-white py-2 px-4 rounded hover:bg-amber-700 transition-colors focus:outline-none focus:ring-2 focus:ring-amber-500"
            aria-label="Enregistrer un nouvel événement">
            Enregistrer
          </button>
        </div>
      </div>

      <div class="bg-amber-50 p-4 md:p-6 rounded-lg shadow-md">
        <h2 class="text-lg md:text-xl font-semibold text-amber-800 mb-4">Événements
        </h2>
        <div class="space-y-2 md:space-y-3" role="list"
          aria-label="Liste des événements">
          <div v-for="event in events" :key="event.id"
            class="bg-white p-3 rounded border border-amber-200 text-sm md:text-base relative"
            role="listitem">
            <div v-if="editingEvent?.id === event.id"
              class="flex items-center space-x-2">
              <input v-model="editValue" type="text"
                class="flex-1 p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500"
                @keyup.enter="saveEditEvent">
              <button @click="saveEditEvent"
                class="p-1 bg-amber-600 text-white rounded hover:bg-amber-700 transition-colors"
                aria-label="Enregistrer">
                <span class="text-sm">✓</span>
              </button>
              <button @click="cancelEditEvent"
                class="p-1 bg-gray-200 text-gray-800 rounded hover:bg-gray-300 transition-colors"
                aria-label="Annuler">
                <span class="text-sm">✕</span>
              </button>
            </div>
            <div v-else>
              <p class="text-amber-800 break-words pr-16">
                {{ formatEventValue(event) }}
              </p>
              <p v-if="tracker.fields[0]?.type === 'text'"
                class="text-xs text-amber-500 mt-1">
                {{ formatEventDate(event) }}
              </p>
              <div class="absolute top-2 right-2 flex space-x-1">
                <button @click="startEditEvent(event)"
                  class="p-1 text-amber-600 hover:text-amber-800 transition-colors focus:outline-none focus:ring-1 focus:ring-amber-500 rounded"
                  aria-label="Modifier l'événement">
                  <PencilSquareIcon class="w-4 h-4" aria-hidden="true" />
                </button>
                <button @click="confirmDeleteEvent(event)"
                  class="p-1 text-red-600 hover:text-red-800 transition-colors focus:outline-none focus:ring-1 focus:ring-red-500 rounded"
                  aria-label="Supprimer l'événement">
                  <TrashIcon class="w-4 h-4" aria-hidden="true" />
                </button>
              </div>
            </div>
          </div>
          <div v-if="events.length === 0"
            class="text-center py-8 bg-white rounded-lg shadow-md">
            <img src="/src/assets/empty-events.svg" alt="Aucun événement"
              class="w-32 h-32 mx-auto mb-4" />
            <p class="text-amber-600">
              Aucun événement enregistré
            </p>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>