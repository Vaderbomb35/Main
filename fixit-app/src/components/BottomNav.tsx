import type { Screen } from '../types'

interface Props {
  current: Screen
  onNavigate: (screen: Screen) => void
}

const tabs = [
  { id: 'home' as Screen, icon: HomeIcon, label: 'Inicio' },
  { id: 'history' as Screen, icon: HistoryIcon, label: 'Historial' },
  { id: 'settings' as Screen, icon: SettingsIcon, label: 'Ajustes' },
]

export default function BottomNav({ current, onNavigate }: Props) {
  return (
    <div style={{
      padding: '0 16px',
      paddingBottom: 'max(16px, env(safe-area-inset-bottom))',
      background: 'linear-gradient(to top, var(--bg-primary) 60%, transparent)',
      position: 'relative',
      zIndex: 50,
    }}>
      <nav style={{
        display: 'flex',
        background: 'rgba(255,255,255,0.05)',
        backdropFilter: 'blur(24px)',
        WebkitBackdropFilter: 'blur(24px)',
        border: '1px solid rgba(255,255,255,0.08)',
        borderRadius: 'var(--radius-xl)',
        padding: '6px',
        gap: '4px',
        boxShadow: '0 8px 32px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.05)',
      }}>
        {tabs.map(tab => {
          const active = current === tab.id
          const Icon = tab.icon
          return (
            <button
              key={tab.id}
              onClick={() => onNavigate(tab.id)}
              style={{
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 3,
                padding: '10px 6px',
                borderRadius: 'var(--radius)',
                background: active
                  ? 'linear-gradient(135deg, rgba(249,115,22,0.2) 0%, rgba(245,158,11,0.12) 100%)'
                  : 'transparent',
                border: active ? '1px solid rgba(249,115,22,0.25)' : '1px solid transparent',
                color: active ? 'var(--orange-light)' : 'var(--text-muted)',
                transition: 'all 0.25s cubic-bezier(0.4,0,0.2,1)',
                boxShadow: active ? '0 4px 16px rgba(249,115,22,0.15)' : 'none',
              }}
            >
              <Icon active={active} />
              <span style={{
                fontSize: 10,
                fontWeight: active ? 700 : 500,
                letterSpacing: '0.02em',
              }}>{tab.label}</span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}

function HomeIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <path
        d="M3 9.5L12 3L21 9.5V20C21 20.55 20.55 21 20 21H15V16H9V21H4C3.45 21 3 20.55 3 20V9.5Z"
        fill={active ? 'url(#homeGrad)' : 'none'}
        stroke={active ? 'none' : 'currentColor'}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      {active && (
        <defs>
          <linearGradient id="homeGrad" x1="0" y1="0" x2="24" y2="24" gradientUnits="userSpaceOnUse">
            <stop stopColor="#f97316" />
            <stop offset="1" stopColor="#fbbf24" />
          </linearGradient>
        </defs>
      )}
    </svg>
  )
}

function HistoryIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="9"
        stroke={active ? 'url(#histGrad)' : 'currentColor'}
        strokeWidth="1.8"
        fill={active ? 'rgba(249,115,22,0.1)' : 'none'}
      />
      <path d="M12 7V12L15 15" stroke={active ? '#fbbf24' : 'currentColor'} strokeWidth="1.8" strokeLinecap="round"/>
      {active && (
        <defs>
          <linearGradient id="histGrad" x1="0" y1="0" x2="24" y2="24" gradientUnits="userSpaceOnUse">
            <stop stopColor="#f97316" />
            <stop offset="1" stopColor="#fbbf24" />
          </linearGradient>
        </defs>
      )}
    </svg>
  )
}

function SettingsIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="3"
        stroke={active ? '#fbbf24' : 'currentColor'}
        strokeWidth="1.8"
        fill={active ? 'rgba(249,115,22,0.2)' : 'none'}
      />
      <path
        d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z"
        stroke={active ? 'url(#setGrad)' : 'currentColor'}
        strokeWidth="1.8"
      />
      {active && (
        <defs>
          <linearGradient id="setGrad" x1="0" y1="0" x2="24" y2="24" gradientUnits="userSpaceOnUse">
            <stop stopColor="#f97316" />
            <stop offset="1" stopColor="#fbbf24" />
          </linearGradient>
        </defs>
      )}
    </svg>
  )
}
