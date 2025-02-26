[![Netlify Status](https://api.netlify.com/api/v1/badges/0026d86e-8d94-44dd-9c4c-a91ea9950d76/deploy-status?branch=main)](https://app.netlify.com/sites/trackers-mlg/deploys)

# Tracker App

A Vue 3 application for creating and managing personal trackers. Built with Vue 3, TypeScript, Vite, and Supabase.

![Tracker App Screenshot](https://github.com/user-attachments/assets/0a63f285-8d68-4967-830b-46c4e26d4c9f)


## Features

- 🔐 User authentication (sign up/sign in)
- 📊 Create custom trackers with different field types (date, datetime, text)
- 📝 Record events for each tracker
- 📱 Responsive design with Tailwind CSS
- 🔄 Real-time updates with Supabase
- 🗑️ Edit and delete trackers and events

## Prerequisites

- [Node.js](https://nodejs.org/) (v16 or newer)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- [Supabase](https://supabase.com/) account

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd tracker-app
```

### 2. Install dependencies

```bash
npm install
# or
yarn install
```

### 3. Set up Supabase

1. Create a new Supabase project at [https://app.supabase.com/](https://app.supabase.com/)
2. Once your project is created, go to the project dashboard
3. Click on "Settings" in the sidebar, then "API"
4. Find your project URL and anon/public key

### 4. Configure environment variables

Create a `.env` file in the root of your project with the following variables:

```
VITE_SUPABASE_URL=your-supabase-project-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

Replace `your-supabase-project-url` and `your-supabase-anon-key` with the values from your Supabase project.

### 5. Set up the database schema

1. In your Supabase project dashboard, go to the "SQL Editor" section
2. Create a new query and paste the contents of the `supabase/migrations/20250109143922_orange_dune.sql` file
3. Run the query to create the necessary tables and set up Row Level Security (RLS)

Alternatively, you can use the Supabase CLI to apply migrations:

```bash
npx supabase link --project-ref your-project-ref
npx supabase db push
```

### 6. Start the development server

```bash
npm run dev
# or
yarn dev
```

The application will be available at [http://localhost:5173](http://localhost:5173)

## Database Schema

The application uses two main tables:

### Trackers

Stores information about each tracker:

- `id`: UUID primary key
- `name`: Text name of the tracker
- `created_at`: Timestamp when the tracker was created
- `user_id`: UUID of the user who created the tracker
- `fields`: JSONB array of field definitions

### Events

Stores events recorded for each tracker:

- `id`: UUID primary key
- `tracker_id`: UUID reference to the tracker
- `created_at`: Timestamp when the event was created
- `user_id`: UUID of the user who created the event
- `data`: JSONB object containing the event data

## Building for Production

```bash
npm run build
# or
yarn build
```

The built files will be in the `dist` directory.

## Deployment

You can deploy this application to any static hosting service that supports single-page applications:

- [Netlify](https://www.netlify.com/)
- [Vercel](https://vercel.com/)
- [GitHub Pages](https://pages.github.com/)
- [Cloudflare Pages](https://pages.cloudflare.com/)

Make sure to configure your environment variables on your hosting provider.

## License

[MIT](LICENSE)
