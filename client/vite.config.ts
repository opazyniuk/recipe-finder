import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    // In dev, proxy API calls to the Rails server so there is no CORS.
    // In prod, the Dockerfile copies the Vite build into Rails' public/ (single origin).
    proxy: {
      // Defaults to the standard Rails port; override with VITE_API_TARGET if 3000 is taken.
      '/api': process.env.VITE_API_TARGET || 'http://localhost:3000',
    },
  },
})
