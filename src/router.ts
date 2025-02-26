import { createRouter, createWebHistory } from 'vue-router'
import Home from './views/Home.vue'
import TrackerDetail from './views/TrackerDetail.vue'
import CreateTracker from './views/CreateTracker.vue'
import Auth from './views/Auth.vue'
import { supabase } from './supabase'

// @ts-ignore to allow build
const requireAuth = async (to, from, next) => {
  const { data: { session } } = await supabase!.auth.getSession()
  if (!session) {
    next('/auth')
  } else {
    next()
  }
}

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: Home,
      beforeEnter: requireAuth
    },
    {
      path: '/tracker/new',
      component: CreateTracker,
      beforeEnter: requireAuth
    },
    {
      path: '/tracker/:id',
      component: TrackerDetail,
      beforeEnter: requireAuth
    },
    {
      path: '/auth',
      component: Auth
    }
  ]
})