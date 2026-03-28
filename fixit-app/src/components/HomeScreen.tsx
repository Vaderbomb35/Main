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
      display: 'flex',
      flexDirection: 'column',
      padding: '0 20px',
      paddingTop: 'max(48px, env(safe-area-inset-top))',
    }}>
      {/* Header */}
      <div style={{ marginBottom: 40 }} className="animate-fade-in">
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
          <span style={{ fontSize: 32 }}>🔧</span>
          <h1 style={{
            fontSize: 28,
            fontWeight: 800,
            background: 'linear-gradient(135deg, var(--orange) 0%, #fbbf24 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
          }}>FixIt</h1>
        </div>
        <p style={{ color: 'var(--text-secondary)', fontSize: 15, lineHeight: 1.5 }}>
          AI-powered home repair diagnosis.<br />
          Describe a problem, get expert guidance.
        </p>
      </div>

      {/* Main CTA */}
      <div className="animate-slide-up" style={{ animationDelay: '0.1s', animationFillMode: 'both' }}>
        <button
          onClick={onDiagnose}
          style={{
            width: '100%',
            padding: '20px',
            background: hasApiKey
              ? 'linear-gradient(135deg, var(--orange) 0%, var(--orange-dark) 100%)'
              : 'var(--bg-card)',
            border: hasApiKey ? 'none' : '2px dashed var(--border-light)',
            borderRadius: 'var(--radius-lg)',
            color: hasApiKey ? '#fff' : 'var(--text-muted)',
            fontSize: 18,
            fontWeight: 700,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 10,
            boxShadow: hasApiKey ? '0 8px 32px rgba(249, 115, 22, 0.35)' : 'none',
            transform: 'scale(1)',
            transition: 'transform 0.15s ease, box-shadow 0.15s ease',
            minHeight: 120,
            flexDirection: 'column',
          }}
          onTouchStart={e => {
            if (hasApiKey) (e.currentTarget as HTMLButtonElement).style.transform = 'scale(0.98)'
          }}
          onTouchEnd={e => {
            (e.currentTarget as HTMLButtonElement).style.transform = 'scale(1)'
          }}
        >
          <span style={{ fontSize: 36 }}>{hasApiKey ? '🔍' : '🔑'}</span>
          <span>{hasApiKey ? 'Diagnose a Problem' : 'Add API Key to Start'}</span>
          {!hasApiKey && (
            <span style={{ fontSize: 12, fontWeight: 400, color: 'var(--text-muted)' }}>
              Go to Settings to add your Anthropic API key
            </span>
          )}
        </button>
      </div>

      {/* Stats / Recent */}
      <div style={{ marginTop: 32, animationDelay: '0.2s', animationFillMode: 'both' }} className="animate-slide-up">
        <h2 style={{ fontSize: 14, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 12 }}>
          How It Works
        </h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
            { icon: '📝', title: 'Describe the problem', desc: 'Type what you see or notice' },
            { icon: '📷', title: 'Add a photo (optional)', desc: 'Visual context helps the AI' },
            { icon: '🧠', title: 'Get AI diagnosis', desc: 'Powered by Claude' },
            { icon: '🔨', title: 'Fix it or call a pro', desc: 'Clear DIY steps or contractor guidance' },
          ].map((step, i) => (
            <div key={i} style={{
              display: 'flex',
              alignItems: 'flex-start',
              gap: 12,
              padding: '12px 14px',
              background: 'var(--bg-card)',
              borderRadius: 'var(--radius)',
              border: '1px solid var(--border)',
            }}>
              <span style={{ fontSize: 20, flexShrink: 0 }}>{step.icon}</span>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 2 }}>{step.title}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{step.desc}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {historyCount > 0 && (
        <div style={{
          marginTop: 24,
          padding: '12px 14px',
          background: 'var(--orange-glow)',
          border: '1px solid rgba(249,115,22,0.3)',
          borderRadius: 'var(--radius)',
          color: 'var(--orange-light)',
          fontSize: 13,
          textAlign: 'center',
        }}>
          📋 {historyCount} past {historyCount === 1 ? 'diagnosis' : 'diagnoses'} saved
        </div>
      )}

      <div style={{ height: 32 }} />
    </div>
  )
}
