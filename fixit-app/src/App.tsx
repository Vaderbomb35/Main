import { useState, useCallback } from 'react'
import type { Screen, Diagnosis } from './types'
import HomeScreen from './components/HomeScreen'
import InputScreen from './components/InputScreen'
import ResultsScreen from './components/ResultsScreen'
import HistoryScreen from './components/HistoryScreen'
import SettingsScreen from './components/SettingsScreen'
import BottomNav from './components/BottomNav'

const HISTORY_KEY = 'fixit_history'

function loadHistory(): Diagnosis[] {
  try {
    const stored = localStorage.getItem(HISTORY_KEY)
    return stored ? JSON.parse(stored) : []
  } catch {
    return []
  }
}

function saveHistory(history: Diagnosis[]) {
  localStorage.setItem(HISTORY_KEY, JSON.stringify(history))
}

export default function App() {
  const [screen, setScreen] = useState<Screen>('home')
  const [history, setHistory] = useState<Diagnosis[]>(loadHistory)
  const [currentDiagnosis, setCurrentDiagnosis] = useState<Diagnosis | null>(null)
  const [viewingHistoryItem, setViewingHistoryItem] = useState<Diagnosis | null>(null)

  const handleDiagnosisComplete = useCallback((diagnosis: Diagnosis) => {
    setCurrentDiagnosis(diagnosis)
    setHistory(prev => {
      const updated = [diagnosis, ...prev].slice(0, 50)
      saveHistory(updated)
      return updated
    })
    setScreen('results')
  }, [])

  const handleViewHistory = useCallback((item: Diagnosis) => {
    setViewingHistoryItem(item)
    setCurrentDiagnosis(item)
    setScreen('results')
  }, [])

  const handleClearHistory = useCallback(() => {
    setHistory([])
    saveHistory([])
  }, [])

  const handleDeleteHistoryItem = useCallback((id: string) => {
    setHistory(prev => {
      const updated = prev.filter(d => d.id !== id)
      saveHistory(updated)
      return updated
    })
  }, [])

  const handleBack = useCallback(() => {
    if (viewingHistoryItem) {
      setViewingHistoryItem(null)
      setScreen('history')
    } else {
      setScreen('home')
    }
  }, [viewingHistoryItem])

  const handleNewDiagnosis = useCallback(() => {
    setViewingHistoryItem(null)
    setCurrentDiagnosis(null)
    setScreen('input')
  }, [])

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
        {screen === 'home' && (
          <HomeScreen onDiagnose={handleNewDiagnosis} historyCount={history.length} />
        )}
        {screen === 'input' && (
          <InputScreen
            onComplete={handleDiagnosisComplete}
            onBack={() => setScreen('home')}
          />
        )}
        {screen === 'results' && currentDiagnosis && (
          <ResultsScreen
            diagnosis={currentDiagnosis}
            onBack={handleBack}
            onNewDiagnosis={handleNewDiagnosis}
          />
        )}
        {screen === 'history' && (
          <HistoryScreen
            history={history}
            onView={handleViewHistory}
            onDelete={handleDeleteHistoryItem}
            onClear={handleClearHistory}
          />
        )}
        {screen === 'settings' && (
          <SettingsScreen onBack={() => setScreen('home')} />
        )}
      </div>
      {(screen === 'home' || screen === 'history' || screen === 'settings') && (
        <BottomNav current={screen} onNavigate={setScreen} />
      )}
    </div>
  )
}
