interface Props {
  onDiagnose: () => void
  historyCount: number
}

export default function HomeScreen({ onDiagnose, historyCount }: Props) {
  const hasApiKey = !!localStorage.getItem('fixit_api_key')

  return (
    <div style={{
      height: '100%',
      overflow: 'auto',
      position: 'relative',
      display: 'flex',
      flexDirection: 'column',
    }}>
      {/* Ambient background orbs */}
      <div style={{
        position: 'absolute', top: -60, right: -40,
        width: 260, height: 260,
        background: 'radial-gradient(circle, rgba(249,115,22,0.18) 0%, transparent 70%)',
        borderRadius: '50%',
        animation: 'orb-drift 10s ease-in-out infinite',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', top: 180, left: -80,
        width: 220, height: 220,
        background: 'radial-gradient(circle, rgba(245,158,11,0.12) 0%, transparent 70%)',
        borderRadius: '50%',
        animation: 'orb-drift2 13s ease-in-out infinite',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', bottom: 60, right: -30,
        width: 180, height: 180,
        background: 'radial-gradient(circle, rgba(251,191,36,0.1) 0%, transparent 70%)',
        borderRadius: '50%',
        animation: 'orb-drift 16s ease-in-out infinite reverse',
        pointerEvents: 'none',
      }} />

      {/* Content */}
      <div style={{ position: 'relative', zIndex: 1, padding: '0 22px', flex: 1 }}>

        {/* Top bar */}
        <div style={{
          paddingTop: 'max(52px, env(safe-area-inset-top))',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 36,
        }} className="anim-fade">
          {/* Logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 42, height: 42,
              background: 'var(--grad-brand)',
              borderRadius: 14,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 22,
              boxShadow: '0 4px 20px rgba(249,115,22,0.4)',
            }}>
              🔧
            </div>
            <div>
              <div style={{
                fontSize: 22, fontWeight: 800, letterSpacing: '-0.03em',
                background: 'var(--grad-brand)',
                WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
                lineHeight: 1,
              }}>FixIt</div>
              <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 500, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
                AI Repair
              </div>
            </div>
          </div>

          {/* Badge */}
          {historyCount > 0 && (
            <div style={{
              padding: '6px 12px',
              background: 'rgba(249,115,22,0.1)',
              border: '1px solid rgba(249,115,22,0.2)',
              borderRadius: 'var(--radius-full)',
              fontSize: 12,
              color: 'var(--orange-light)',
              fontWeight: 600,
            }}>
              {historyCount} diagnóstico{historyCount !== 1 ? 's' : ''}
            </div>
          )}
        </div>

        {/* Hero text */}
        <div style={{ marginBottom: 32 }}>
          <div style={{
            fontSize: 34, fontWeight: 900, letterSpacing: '-0.04em', lineHeight: 1.12,
            marginBottom: 14,
          }} className="anim-fade-up">
            <span style={{ color: 'var(--text-primary)' }}>Diagnostica</span>{' '}
            <span className="shimmer-text">cualquier</span>
            <br />
            <span style={{ color: 'var(--text-primary)' }}>problema del</span>{' '}
            <span style={{ color: 'var(--orange-light)' }}>hogar</span>
          </div>
          <p style={{
            fontSize: 15, color: 'var(--text-secondary)', lineHeight: 1.65,
            animation: 'fadeUp 0.5s 0.1s ease both',
          }}>
            Inteligencia artificial que analiza fotos y descripciones para darte una solución exacta al instante.
          </p>
        </div>

        {/* CTA Button */}
        <div style={{ animation: 'fadeUp 0.5s 0.15s ease both', marginBottom: 32 }}>
          {hasApiKey ? (
            <button
              onClick={onDiagnose}
              className="btn-primary"
              style={{
                width: '100%', padding: '18px 24px',
                fontSize: 17, fontWeight: 800, letterSpacing: '-0.01em',
                borderRadius: 'var(--radius-lg)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
                animation: 'pulse-glow 3s ease-in-out infinite',
                minHeight: 62,
              }}
            >
              <span style={{ fontSize: 22 }}>🔍</span>
              <span>Diagnosticar Problema</span>
              <span style={{
                marginLeft: 4,
                background: 'rgba(255,255,255,0.2)',
                borderRadius: 8, padding: '3px 8px', fontSize: 14,
              }}>→</span>
            </button>
          ) : (
            <button
              onClick={onDiagnose}
              style={{
                width: '100%', padding: '18px 24px',
                background: 'var(--bg-card)',
                border: '1.5px dashed rgba(249,115,22,0.35)',
                borderRadius: 'var(--radius-lg)',
                color: 'var(--orange-light)',
                fontSize: 16, fontWeight: 700,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
                flexDirection: 'column', minHeight: 80,
              }}
            >
              <span style={{ fontSize: 24 }}>🔑</span>
              <span>Añade tu API Key para comenzar</span>
              <span style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 400 }}>
                Ve a Ajustes → Ingresar clave de Anthropic
              </span>
            </button>
          )}
        </div>

        {/* Stats row */}
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
          gap: 10, marginBottom: 32,
          animation: 'fadeUp 0.5s 0.2s ease both',
        }}>
          {[
            { value: 'IA', label: 'Inteligencia\nArtificial', icon: '🧠' },
            { value: '6', label: 'Puntos de\ndiagnóstico', icon: '📊' },
            { value: '∞', label: 'Problemas\ndiagnosticados', icon: '🔧' },
          ].map((stat, i) => (
            <div key={i} style={{
              padding: '14px 10px',
              background: 'var(--grad-card)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius)',
              textAlign: 'center',
              backdropFilter: 'blur(10px)',
            }}>
              <div style={{ fontSize: 18, marginBottom: 4 }}>{stat.icon}</div>
              <div style={{
                fontSize: 20, fontWeight: 900, letterSpacing: '-0.03em',
                background: 'var(--grad-brand)',
                WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
                lineHeight: 1,
              }}>{stat.value}</div>
              <div style={{
                fontSize: 10, color: 'var(--text-muted)', marginTop: 4, lineHeight: 1.3,
                whiteSpace: 'pre-line',
              }}>{stat.label}</div>
            </div>
          ))}
        </div>

        {/* How it works */}
        <div style={{ animation: 'fadeUp 0.5s 0.25s ease both', marginBottom: 24 }}>
          <p style={{
            fontSize: 11, color: 'var(--text-muted)', fontWeight: 700,
            letterSpacing: '0.1em', textTransform: 'uppercase', marginBottom: 14,
          }}>Cómo funciona</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { icon: '📝', title: 'Describe el problema', desc: 'Escribe qué ves o notas en tu hogar', color: '#6366f1' },
              { icon: '📷', title: 'Sube una foto', desc: 'El contexto visual mejora el diagnóstico', color: '#8b5cf6' },
              { icon: '🧠', title: 'IA analiza en segundos', desc: 'Claude examina todos los detalles', color: '#f97316' },
              { icon: '✅', title: 'Solución exacta', desc: 'Pasos DIY o contacto con el especialista', color: '#10b981' },
            ].map((step, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 14,
                padding: '13px 14px',
                background: 'var(--grad-card)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius)',
                backdropFilter: 'blur(8px)',
                transition: 'border-color var(--transition)',
              }}>
                <div style={{
                  width: 38, height: 38, flexShrink: 0,
                  background: `${step.color}18`,
                  border: `1px solid ${step.color}35`,
                  borderRadius: 12,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 18,
                }}>
                  {step.icon}
                </div>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 2 }}>{step.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)', lineHeight: 1.4 }}>{step.desc}</div>
                </div>
                <div style={{
                  marginLeft: 'auto', flexShrink: 0,
                  width: 22, height: 22,
                  background: `${step.color}15`,
                  border: `1px solid ${step.color}30`,
                  borderRadius: '50%',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 11, color: step.color, fontWeight: 800,
                }}>{i + 1}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ height: 16 }} />
      </div>
    </div>
  )
}
