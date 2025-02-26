<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase, isSupabaseConfigured } from '../supabase'
import type { TrackerField } from '../types'

const router = useRouter()
const name = ref('')
const selectedType = ref<'date' | 'datetime' | 'text'>('date')
const isConfigured = ref(isSupabaseConfigured())

const createTracker = async () => {
  if (!isConfigured.value || !name.value) return

  const field: TrackerField = {
    type: selectedType.value,
    name: 'Value'
  }

  const { data } = await supabase!
    .from('trackers')
    .insert([
      {
        name: name.value,
        fields: [field]
      }
    ])
    .select()

  if (data) {
    router.push('/')
  }
}
</script>

<template>
  <div class="max-w-4xl mx-auto p-4">
    <h1 class="text-2xl md:text-3xl font-bold text-amber-700 mb-6 md:mb-8">Nouveau Tracker</h1>

    <div class="bg-white p-4 md:p-6 rounded-lg shadow-md">
      <div class="space-y-6">
        <div>
          <label class="block text-amber-700 text-sm md:text-base mb-2">Nom du tracker</label>
          <input
            v-model="name"
            type="text"
            class="w-full p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm md:text-base"
            placeholder="Nom du tracker"
          >
        </div>

        <div>
          <label class="block text-amber-700 text-sm md:text-base mb-2">Type de valeur à suivre</label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="type in ['date', 'datetime', 'text']"
              :key="type"
              @click="selectedType = type as 'date' | 'datetime' | 'text'"
              class="px-3 md:px-4 py-1.5 md:py-2 rounded transition-colors text-sm md:text-base"
              :class="selectedType === type 
                ? 'bg-amber-600 text-white' 
                : 'bg-amber-100 text-amber-800 hover:bg-amber-200'"
            >
              {{ type }}
            </button>
          </div>
        </div>

        <button
          @click="createTracker"
          :disabled="!name"
          :class="{
            'opacity-50 cursor-not-allowed': !name
          }"
          class="w-full bg-amber-600 text-white py-2 px-4 rounded hover:bg-amber-700 transition-colors text-sm md:text-base"
        >
          Créer le tracker
        </button>
      </div>
    </div>
  </div>
</template>