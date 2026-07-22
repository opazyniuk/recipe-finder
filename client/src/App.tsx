import { Route, Routes } from 'react-router-dom'
import { HomePage } from './pages/HomePage'
import { RecipePage } from './pages/RecipePage'

function App() {
  return (
    <div className="min-h-screen bg-zinc-50 text-zinc-900">
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/recipes/:id" element={<RecipePage />} />
      </Routes>
    </div>
  )
}

export default App
