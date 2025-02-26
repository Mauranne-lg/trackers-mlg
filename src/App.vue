<script setup lang="ts">
import { onMounted } from 'vue'
import { supabase } from './supabase'
import { useRouter } from 'vue-router'

const router = useRouter()

onMounted(() => {
  supabase?.auth.onAuthStateChange((event) => {
    if (event === 'SIGNED_OUT') {
      router.push('/auth')
    } else if (event === 'SIGNED_IN') {
      router.push('/')
    }
  })
})
</script>

<template>
  <router-view></router-view>
</template>