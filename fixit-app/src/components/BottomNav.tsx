import type { Screen } from '../types'

interface Props {
  current: Screen
  onNavigate: (screen: Screen) => void
}

const tabs: { id: Screen; icon: string; label: string }[] = [
  { id: 'home', icon: '🏠', label: 'Home' },
  { id: 'history', icon: '📋', label: 'History' },
  { id: 'settings', icon: '⚙️', label: 'Settings' },
]

export default function BottomNav({ current, onNavigate }: Props) {
  return (
    <nav style={{
      display: 'flex',
      background: 'var(--bg-secondary)',
      borderTop: '1px solid var(--border)',
      paddingBottom: 'env(safe-area-inset-bottom)',
    }}>
      {tabs.map(tab => {
        const active = current === tab.id
        return (
          <button
            key={tab.id}
            onClick={() => onNavigate(tab.id)}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: '2px',
              padding: '10px 0',
              background: 'none',
              color: active ? 'var(--orange)' : 'var(--text-muted)',
              transition: 'color var(--transition)',
              position: 'relative',
            }}
          >
            {active && (
              <span style={{
                position: 'absolute',
                top: 0,
                left: '50%',
                transform: 'translateX(-50%)',
                width: 32,
                height: 2,
                background: 'var(--orange)',
                borderRadius: '0 0 2px 2px',
              }} />
            )}
            <span style={{ fontSize: 22 }}>{tab.icon}</span>
            <span style={{ fontSize: 11, fontWeight: active ? 600 : 400 }}>{tab.label}</span>
          </button>
        )
      })}
    </nav>
  )
}
