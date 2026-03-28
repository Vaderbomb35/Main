import { useState, useEffect } from 'react'

interface Props {
  onBack: () => void
}

export default function SettingsScreen({ onBack }: Props) {
  const [apiKey, setApiKey] = useState('')
  const [saved, setSaved] = useState(false)
  const [showKey, setShowKey] = useState(false)

  useEffect(() => {
    const stored = localStorage.getItem('fixit_api_key')
    if (stored) setApiKey(stored)
  }, [])

  const handleSave = () => {
    const trimmed = apiKey.trim()
    if (trimmed) {
      localStorage.setItem('fixit_api_key', trimmed)
    } else {
      localStorage.removeItem('fixit_api_key')
    }
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  const handleClear = () => {
    setApiKey('')
    localStorage.removeItem('fixit_api_key')
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  const hasStoredKey = !!localStorage.getItem('fixit_api_key')

  return (
    <div style={{
      height: '100%',
      overflow: 'auto',
      display: 'flex',
      flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        padding: '16px 20px',
        paddingTop: 'max(16px, env(safe-area-inset-top))',
        borderBottom: '1px solid var(--border)',
        background: 'var(--bg-secondary)',
      }}>
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>Settings</h1>
      </div>

      <div style={{ padding: '24px 20px', display: 'flex', flexDirection: 'column', gap: 24 }}>

        {/* API Key Section */}
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <h2 style={{ fontSize: 16, fontWeight: 700 }}>Anthropic API Key</h2>
            {hasStoredKey && (
              <span style={{
                padding: '2px 8px',
                background: 'var(--green-bg)',
                border: '1px solid rgba(34,197,94,0.3)',
                borderRadius: 20,
                color: 'var(--green)',
                fontSize: 11,
                fontWeight: 600,
              }}>
                ✓ Saved
              </span>
            )}
          </div>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 12, lineHeight: 1.5 }}>
            Your API key is stored locally on your device only and never sent to any server other than Anthropic's.
          </p>

          <div style={{ position: 'relative', marginBottom: 10 }}>
            <input
              type={showKey ? 'text' : 'password'}
              value={apiKey}
              onChange={e => setApiKey(e.target.value)}
              placeholder="sk-ant-..."
              style={{
                width: '100%',
                padding: '12px 44px 12px 14px',
                background: 'var(--bg-input)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius)',
                color: 'var(--text-primary)',
                fontSize: 14,
                fontFamily: 'monospace',
                letterSpacing: showKey ? 'normal' : '0.1em',
              }}
              onFocus={e => e.currentTarget.style.borderColor = 'var(--orange)'}
              onBlur={e => e.currentTarget.style.borderColor = 'var(--border)'}
              onKeyDown={e => e.key === 'Enter' && handleSave()}
            />
            <button
              onClick={() => setShowKey(!showKey)}
              style={{
                position: 'absolute',
                right: 10,
                top: '50%',
                transform: 'translateY(-50%)',
                background: 'none',
                color: 'var(--text-muted)',
                fontSize: 18,
                padding: 4,
              }}
              title={showKey ? 'Hide' : 'Show'}
            >
              {showKey ? '🙈' : '👁'}
            </button>
          </div>

          <div style={{ display: 'flex', gap: 8 }}>
            <button
              onClick={handleSave}
              style={{
                flex: 1,
                padding: '12px',
                background: saved
                  ? 'var(--green-bg)'
                  : 'linear-gradient(135deg, var(--orange) 0%, var(--orange-dark) 100%)',
                border: saved ? '1px solid rgba(34,197,94,0.3)' : 'none',
                borderRadius: 'var(--radius)',
                color: saved ? 'var(--green)' : '#fff',
                fontSize: 14,
                fontWeight: 700,
                transition: 'all 0.2s',
              }}
            >
              {saved ? '✓ Saved!' : 'Save API Key'}
            </button>
            {apiKey && (
              <button
                onClick={handleClear}
                style={{
                  padding: '12px 16px',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius)',
                  color: 'var(--text-muted)',
                  fontSize: 14,
                }}
              >
                Clear
              </button>
            )}
          </div>
        </div>

        {/* Divider */}
        <div style={{ height: 1, background: 'var(--border)' }} />

        {/* Help */}
        <div>
          <h2 style={{ fontSize: 16, fontWeight: 700, marginBottom: 10 }}>Getting an API Key</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { step: '1', text: 'Go to console.anthropic.com' },
              { step: '2', text: 'Sign up or log in to your account' },
              { step: '3', text: 'Click "API Keys" in the sidebar' },
              { step: '4', text: 'Create a new key and copy it here' },
            ].map(item => (
              <div key={item.step} style={{
                display: 'flex',
                gap: 10,
                alignItems: 'flex-start',
                padding: '10px 12px',
                background: 'var(--bg-card)',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
              }}>
                <span style={{
                  width: 22,
                  height: 22,
                  background: 'var(--orange-glow)',
                  border: '1px solid rgba(249,115,22,0.3)',
                  borderRadius: '50%',
                  color: 'var(--orange)',
                  fontSize: 12,
                  fontWeight: 700,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  {item.step}
                </span>
                <span style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.4, paddingTop: 2 }}>{item.text}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Divider */}
        <div style={{ height: 1, background: 'var(--border)' }} />

        {/* About */}
        <div>
          <h2 style={{ fontSize: 16, fontWeight: 700, marginBottom: 6 }}>About FixIt</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', lineHeight: 1.6 }}>
            FixIt uses Claude (claude-sonnet-4-0) to diagnose home repair problems.
            It analyzes your description and photos to provide plain-English explanations,
            severity assessments, DIY instructions, and contractor recommendations.
          </p>
          <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 10, lineHeight: 1.5 }}>
            ⚠️ Always use professional judgment. For safety hazards (gas leaks, electrical issues, structural problems), call a licensed professional immediately.
          </p>
        </div>

        <div style={{ height: 20 }} />
      </div>
    </div>
  )
}
