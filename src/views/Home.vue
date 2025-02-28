<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase, isSupabaseConfigured } from '../supabase'
import type { Tracker } from '../types'
import { useRouter } from 'vue-router'
import { format } from 'date-fns'
import { PlusIcon } from '@heroicons/vue/24/solid'

const router = useRouter()
const trackers = ref<Tracker[]>([])
const isConfigured = ref(isSupabaseConfigured())
const notification = ref('')
const notificationTimeout = ref<number | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const showModal = ref(false)
const textInput = ref('')
const selectedTracker = ref<Tracker | null>(null)

// Subscribe to real-time updates
const subscribeToTrackers = () => {
  if (!isConfigured.value) return () => { }

  const subscription = supabase!
    .channel('trackers-channel')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'trackers'
      },
      async () => {
        await loadTrackers()
      }
    )
    .subscribe()

  return () => {
    subscription.unsubscribe()
  }
}

const loadTrackers = async () => {
  if (!isConfigured.value) return

  try {
    loading.value = true
    error.value = null

    const { data, error: supabaseError } = await supabase!
      .from('trackers')
      .select('*')
      .order('created_at', { ascending: false })

    if (supabaseError) {
      throw supabaseError
    }

    trackers.value = data || []
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Failed to load trackers'
    console.error('Error loading trackers:', e)
  } finally {
    loading.value = false
  }
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

const openModal = (tracker: Tracker, event: Event) => {
  event.stopPropagation()
  selectedTracker.value = tracker
  textInput.value = ''
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  selectedTracker.value = null
  textInput.value = ''
}

const handleKeyDown = (e: KeyboardEvent) => {
  if (e.key === 'Escape') {
    closeModal()
  }
}

const createEvent = async (tracker: Tracker, event: Event) => {
  event.stopPropagation()
  if (!tracker.fields[0]) return

  const field = tracker.fields[0]
  let fieldValue: string

  if (field.type === 'text') {
    openModal(tracker, event)
    return
  }

  switch (field.type) {
    case 'date':
      fieldValue = format(new Date(), 'yyyy-MM-dd')
      break
    case 'datetime':
      fieldValue = new Date().toISOString()
      break
    default:
      return
  }

  const { error } = await supabase!
    .from('events')
    .insert([
      {
        tracker_id: tracker.id,
        data: { [field.name]: fieldValue }
      }
    ])

  if (!error) {
    showNotification(`Événement ajouté pour "${tracker.name}"`)
  }
}

const submitTextEvent = async () => {
  if (!selectedTracker.value || !textInput.value) return

  const field = selectedTracker.value.fields[0]
  if (!field) return

  const { error } = await supabase!
    .from('events')
    .insert([
      {
        tracker_id: selectedTracker.value.id,
        data: { [field.name]: textInput.value }
      }
    ])

  if (!error) {
    showNotification(`Événement ajouté pour "${selectedTracker.value.name}"`)
    closeModal()
  }
}

const goToCreate = () => {
  router.push('/tracker/new')
}

onMounted(() => {
  const cleanup = subscribeToTrackers()
  loadTrackers()

  onUnmounted(() => {
    if (typeof cleanup === 'function') {
      cleanup()
    }
  })
})
</script>

<template>
  <div class="max-w-4xl mx-auto p-4">
    <template v-if="!isConfigured">
      <div role="alert" class="bg-amber-100 border-l-4 border-amber-500 p-4 mb-8">
        <p class="text-amber-700">
          Please configure your Supabase connection in the .env file.
        </p>
      </div>
    </template>

    <template v-else>
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-2xl md:text-3xl font-bold text-amber-700">Mes Trackers</h1>
        <img src="/src/assets/tracker-illustration.svg" alt="Illustration"
          class="w-32 h-32" />
      </div>

      <button @click="goToCreate"
        class="w-full mb-6 bg-amber-600 hover:bg-amber-700 text-white p-4 rounded-lg shadow-lg transition-all transform hover:scale-105 flex items-center justify-center space-x-2">
        <PlusIcon class="w-6 h-6" />
        <span class="text-lg font-medium">Créer un nouveau tracker</span>
      </button>

      <!-- Error state -->
      <div v-if="error" role="alert"
        class="bg-red-100 border-l-4 border-red-500 p-4 mb-4 rounded">
        <p class="text-red-700">{{ error }}</p>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="flex justify-center items-center py-8">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-600">
        </div>
      </div>

      <!-- Notification -->
      <div v-if="notification" role="status" aria-live="polite"
        class="fixed bottom-4 right-4 bg-green-100 border-l-4 border-green-500 p-4 rounded shadow-lg max-w-[90vw] md:max-w-md z-50">
        <p class="text-green-700 text-sm md:text-base">{{ notification }}</p>
      </div>

      <!-- Modal -->
      <div v-if="showModal"
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
        role="dialog" aria-labelledby="modal-title" @keydown="handleKeyDown">
        <div class="bg-white rounded-lg p-4 md:p-6 w-full max-w-md relative"
          @click.stop>
          <button @click="closeModal"
            class="absolute top-2 right-2 text-gray-500 hover:text-gray-700 focus:outline-none focus:ring-2 focus:ring-amber-500 rounded"
            aria-label="Fermer">
            <span class="text-xl">&times;</span>
          </button>

          <h2 id="modal-title"
            class="text-lg md:text-xl font-bold text-amber-700 mb-4 pr-8">
            Ajouter un événement pour "{{ selectedTracker?.name }}"
          </h2>

          <div class="space-y-4">
            <div>
              <label :for="'modal-text-input'"
                class="block text-sm font-medium text-amber-700 mb-1">
                Texte
              </label>
              <input id="modal-text-input" v-model="textInput" type="text"
                class="w-full p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500"
                placeholder="Entrez votre texte" @keyup.enter="submitTextEvent">
            </div>

            <button @click="submitTextEvent" :disabled="!textInput"
              class="w-full bg-amber-600 text-white py-2 px-4 rounded hover:bg-amber-700 transition-colors focus:outline-none focus:ring-2 focus:ring-amber-500 disabled:opacity-50 disabled:cursor-not-allowed">
              Valider
            </button>
          </div>
        </div>
      </div>

      <div v-if="!loading" class="space-y-3 md:space-y-4" role="list"
        aria-label="Liste des trackers">
        <div v-for="tracker in trackers" :key="tracker.id"
          class="bg-white p-3 md:p-4 rounded-lg shadow border border-amber-200 hover:border-amber-400 transition-all cursor-pointer group"
          role="listitem" @click="() => router.push(`/tracker/${tracker.id}`)">
          <div class="flex items-center space-x-4">
            <div class="min-w-0 flex-1">
              <h2
                class="text-base md:text-lg font-medium text-amber-800 truncate group-hover:text-amber-900">
                {{ tracker.name }}
              </h2>
              <p class="text-xs md:text-sm text-amber-600">
                Créé le {{ format(new Date(tracker.created_at), 'dd/MM/yyyy HH:mm') }}
              </p>
            </div>
            <button @click.stop="(e) => createEvent(tracker, e)"
              class="p-1.5 md:p-2 text-amber-600 hover:text-amber-800 hover:scale-125 transform transition-all focus:outline-none focus:ring-2 focus:ring-amber-500 rounded bg-amber-600"
              :aria-label="`Ajouter un événement pour ${tracker.name}`">
              <PlusIcon class="w-4 h-4 text-white md:w-5 md:h-5" aria-hidden="true" />
            </button>
          </div>
        </div>

        <div v-if="trackers.length === 0 && !loading && !error"
          class="text-center py-12 bg-white rounded-lg shadow-md">
          <img src="/src/assets/empty-state.svg" alt="Aucun tracker"
            class="w-48 h-48 mx-auto mb-4" />
          <p class="text-amber-600 text-lg">
            Aucun tracker créé
          </p>
        </div>
      </div>
    </template>
  </div>
</template>