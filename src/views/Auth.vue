<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../supabase'
import { useRouter } from 'vue-router'

const email = ref('')
const password = ref('')
const error = ref('')
const router = useRouter()

const signUp = async () => {
  error.value = ''
  if (!email.value || !password.value) {
    error.value = 'Veuillez remplir tous les champs'
    return
  }
  
  const { error: signUpError } = await supabase!.auth.signUp({
    email: email.value,
    password: password.value,
  })
  
  if (signUpError) {
    error.value = signUpError.message
  }
}

const signIn = async () => {
  error.value = ''
  if (!email.value || !password.value) {
    error.value = 'Veuillez remplir tous les champs'
    return
  }
  
  const { error: signInError } = await supabase!.auth.signInWithPassword({
    email: email.value,
    password: password.value,
  })
  
  if (signInError) {
    error.value = signInError.message
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-amber-50 px-4">
    <div class="bg-white p-6 md:p-8 rounded-lg shadow-md w-full max-w-md">
      <h1 class="text-xl md:text-2xl font-bold text-amber-700 mb-6">Connexion</h1>
      
      <div v-if="error" class="bg-red-100 border-l-4 border-red-500 p-4 mb-4">
        <p class="text-red-700 text-sm md:text-base">{{ error }}</p>
      </div>
      
      <div class="space-y-4">
        <div>
          <label class="block text-amber-700 text-sm md:text-base mb-1">Email</label>
          <input
            v-model="email"
            type="email"
            class="w-full p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm md:text-base"
          >
        </div>
        
        <div>
          <label class="block text-amber-700 text-sm md:text-base mb-1">Mot de passe</label>
          <input
            v-model="password"
            type="password"
            class="w-full p-2 border border-amber-300 rounded focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm md:text-base"
            @keyup.enter="signIn"
          >
        </div>
        
        <div class="space-y-2">
          <button
            @click="signIn"
            class="w-full bg-amber-600 text-white py-2 px-4 rounded hover:bg-amber-700 transition-colors text-sm md:text-base"
          >
            Se connecter
          </button>
          
          <button
            @click="signUp"
            class="w-full bg-amber-100 text-amber-800 py-2 px-4 rounded hover:bg-amber-200 transition-colors text-sm md:text-base"
          >
            Créer un compte
          </button>
        </div>
      </div>
    </div>
  </div>
</template>