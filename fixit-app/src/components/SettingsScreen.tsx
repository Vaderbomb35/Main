import { useState, useEffect } from 'react'

export default function SettingsScreen() {
  const [apiKey, setApiKey] = useState('')
  const [saved, setSaved] = useState(false)
  const [showKey, setShowKey] = useState(false)
  const [focused, setFocused] = useState(false)

  useEffect(() => {
    const k = localStorage.getItem('fixit_api_key')
    if (k) setApiKey(k)
  }, [])

  const handleSave = () => {
    const k = apiKey.trim()
    k ? localStorage.setItem('fixit_api_key', k) : localStorage.removeItem('fixit_api_key')
    setSaved(true); setTimeout(() => setSaved(false), 2500)
  }

  const handleClear = () => {
    setApiKey(''); localStorage.removeItem('fixit_api_key')
    setSaved(true); setTimeout(() => setSaved(false), 2000)
  }

  const hasKey = !!localStorage.getItem('fixit_api_key')
  const isValidFormat = apiKey.trim().startsWith('sk-ant-')

  return (
    <div style={{ height: '100%', overflow: 'auto', position: 'relative' }}>
      {/* Ambient */}
      <div style={{
        position: 'absolute', top: -60, left: -60, width: 200, height: 200,
        background: 'radial-gradient(circle, rgba(99,102,241,0.1) 0%, transparent 70%)',
        borderRadius: '50%', pointerEvents: 'none',
        animation: 'orb-drift 14s ease-in-out infinite',
      }} />

      {/* Header */}
      <div style={{
        padding: '16px 18px',
        paddingTop: 'max(16px, env(safe-area-inset-top))',
        borderBottom: '1px solid var(--border)',
        background: 'rgba(8,12,20,0.9)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        position: 'sticky', top: 0, zIndex: 20,
      }}>
        <h1 style={{ fontSize: 22, fontWeight: 900, letterSpacing: '-0.03em' }}>Ajustes</h1>
        <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>Configura tu clave de API</p>
      </div>

      <div style={{ padding: '22px 18px', display: 'flex', flexDirection: 'column', gap: 22, position: 'relative', zIndex: 1 }}>

        {/* API Key card */}
        <div style={{
          background: 'var(--grad-card)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-xl)',
          overflow: 'hidden',
        }} className="anim-fade-up">
          {/* Card header */}
          <div style={{
            padding: '16px 18px',
            borderBottom: '1px solid var(--border)',
            background: 'rgba(249,115,22,0.04)',
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 36, height: 36,
                background: 'var(--grad-brand)',
                borderRadius: 10,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18,
              }}>🔑</div>
              <div>
                <div style={{ fontSize: 15, fontWeight: 800 }}>Clave de API Anthropic</div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1 }}>
                  Guardada solo en tu dispositivo
                </div>
              </div>
            </div>
            {hasKey && (
              <div style={{
                padding: '4px 10px',
                background: 'rgba(16,185,129,0.1)',
                border: '1px solid rgba(16,185,129,0.25)',
                borderRadius: 'var(--radius-full)',
                fontSize: 11, fontWeight: 700, color: 'var(--green)',
                display: 'flex', alignItems: 'center', gap: 4,
              }}>
                <span style={{ fontSize: 8, background: 'var(--green)', borderRadius: '50%', width: 6, height: 6, display: 'inline-block' }} />
                Activa
              </div>
            )}
          </div>

          <div style={{ padding: '16px 18px', display: 'flex', flexDirection: 'column', gap: 12 }}>
            {/* Input */}
            <div style={{
              display: 'flex', alignItems: 'center',
              background: 'var(--bg-input)',
              border: `1.5px solid ${focused ? 'var(--orange)' : isValidFormat && apiKey ? 'rgba(16,185,129,0.4)' : 'var(--border)'}`,
              borderRadius: 'var(--radius)',
              overflow: 'hidden',
              transition: 'border-color var(--transition)',
              boxShadow: focused ? '0 0 0 3px rgba(249,115,22,0.12)' : 'none',
            }}>
              <input
                type={showKey ? 'text' : 'password'}
                value={apiKey}
                onChange={e => setApiKey(e.target.value)}
                placeholder="sk-ant-api03-..."
                onFocus={() => setFocused(true)}
                onBlur={() => setFocused(false)}
                onKeyDown={e => e.key === 'Enter' && handleSave()}
                style={{
                  flex: 1, padding: '13px 14px',
                  background: 'transparent', color: 'var(--text-primary)',
                  fontSize: 13, fontFamily: 'monospace',
                  letterSpacing: showKey ? 'normal' : '0.15em',
                  border: 'none',
                }}
              />
              <button
                onClick={() => setShowKey(!showKey)}
                style={{
                  padding: '0 14px', height: '100%',
                  background: 'none', color: 'var(--text-muted)', fontSize: 17,
                  borderLeft: '1px solid var(--border)',
                  display: 'flex', alignItems: 'center',
                }}
              >{showKey ? '🙈' : '👁'}</button>
            </div>

            {/* Validation hint */}
            {apiKey && !isValidFormat && (
              <p style={{ fontSize: 12, color: 'var(--yellow)', display: 'flex', gap: 5, alignItems: 'center' }}>
                <span>⚠️</span> Las claves de Anthropic empiezan por "sk-ant-"
              </p>
            )}
            {isValidFormat && apiKey && (
              <p style={{ fontSize: 12, color: 'var(--green)', display: 'flex', gap: 5, alignItems: 'center' }}>
                <span>✅</span> Formato correcto
              </p>
            )}

            {/* Buttons */}
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                onClick={handleSave}
                style={{
                  flex: 1, padding: '13px',
                  background: saved ? 'linear-gradient(135deg, #10b981, #059669)' : 'var(--grad-brand)',
                  borderRadius: 'var(--radius)',
                  color: '#fff', fontSize: 14, fontWeight: 800,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                  boxShadow: saved ? '0 4px 16px rgba(16,185,129,0.3)' : 'var(--shadow-orange)',
                  transition: 'all 0.3s',
                }}
              >
                {saved ? <><span>✓</span> Guardado</> : <><span>💾</span> Guardar</>}
              </button>
              {apiKey && (
                <button
                  onClick={handleClear}
                  style={{
                    padding: '13px 16px',
                    background: 'rgba(239,68,68,0.08)',
                    border: '1px solid rgba(239,68,68,0.2)',
                    borderRadius: 'var(--radius)',
                    color: 'var(--red)', fontSize: 14,
                  }}
                >Borrar</button>
              )}
            </div>
          </div>
        </div>

        {/* How to get key */}
        <div style={{ animation: 'fadeUp 0.4s 0.1s ease both' }}>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', marginBottom: 14 }}>
            Cómo obtener tu clave
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { step: 1, text: 'Ve a console.anthropic.com', icon: '🌐', color: '#6366f1' },
              { step: 2, text: 'Crea una cuenta o inicia sesión', icon: '👤', color: '#8b5cf6' },
              { step: 3, text: 'Haz clic en "API Keys" en el menú lateral', icon: '🔑', color: '#f97316' },
              { step: 4, text: 'Crea una nueva clave y pégala aquí', icon: '✨', color: '#10b981' },
            ].map(item => (
              <div key={item.step} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '12px 14px',
                background: 'var(--grad-card)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius)',
              }}>
                <div style={{
                  width: 34, height: 34, flexShrink: 0,
                  background: `${item.color}12`,
                  border: `1px solid ${item.color}28`,
                  borderRadius: 10,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 17,
                }}>{item.icon}</div>
                <span style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.4, flex: 1 }}>{item.text}</span>
                <div style={{
                  width: 20, height: 20, flexShrink: 0,
                  background: `${item.color}15`,
                  border: `1px solid ${item.color}30`,
                  borderRadius: '50%',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 11, color: item.color, fontWeight: 800,
                }}>{item.step}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Divider */}
        <div style={{ height: 1, background: 'var(--border)' }} />

        {/* About */}
        <div style={{ animation: 'fadeUp 0.4s 0.2s ease both' }}>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 700, letterSpacing: '0.09em', textTransform: 'uppercase', marginBottom: 14 }}>
            Acerca de FixIt
          </p>
          <div style={{
            padding: '16px',
            background: 'var(--grad-card)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-lg)',
            display: 'flex', flexDirection: 'column', gap: 10,
          }}>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <div style={{
                width: 44, height: 44,
                background: 'var(--grad-brand)',
                borderRadius: 14, fontSize: 22,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 4px 16px rgba(249,115,22,0.3)',
              }}>🔧</div>
              <div>
                <div style={{ fontSize: 16, fontWeight: 800 }}>FixIt v1.0</div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Diagnóstico de reparaciones del hogar</div>
              </div>
            </div>
            <p style={{ fontSize: 13, color: 'var(--text-muted)', lineHeight: 1.65 }}>
              Utiliza el modelo Claude (claude-sonnet-4-0) para diagnosticar problemas en el hogar a partir de descripciones y fotos. Analiza la gravedad, sugiere reparaciones DIY o recomienda profesionales.
            </p>
            <div style={{
              padding: '10px 12px',
              background: 'rgba(245,158,11,0.07)',
              border: '1px solid rgba(245,158,11,0.18)',
              borderRadius: 10,
              fontSize: 12, color: 'rgba(245,158,11,0.8)', lineHeight: 1.55,
            }}>
              ⚠️ Ante riesgos de seguridad (gas, electricidad, estructuras), llama siempre a un profesional cualificado de inmediato.
            </div>
          </div>
        </div>

        <div style={{ height: 24 }} />
      </div>
    </div>
  )
}
