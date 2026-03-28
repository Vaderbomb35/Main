import type { Diagnosis, SeverityLevel } from '../types'

interface Props {
  diagnosis: Diagnosis
  onBack: () => void
  onNewDiagnosis: () => void
}

const SEVERITY_CONFIG: Record<SeverityLevel, { label: string; color: string; bg: string; border: string; icon: string }> = {
  low: {
    label: 'Low Severity',
    color: 'var(--green)',
    bg: 'var(--green-bg)',
    border: 'rgba(34,197,94,0.3)',
    icon: '🟢',
  },
  medium: {
    label: 'Medium Severity',
    color: 'var(--yellow)',
    bg: 'var(--yellow-bg)',
    border: 'rgba(234,179,8,0.3)',
    icon: '🟡',
  },
  high: {
    label: 'High Severity',
    color: 'var(--red)',
    bg: 'var(--red-bg)',
    border: 'rgba(239,68,68,0.3)',
    icon: '🔴',
  },
}

function formatDate(ts: number) {
  return new Date(ts).toLocaleDateString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric',
    hour: 'numeric', minute: '2-digit',
  })
}

export default function ResultsScreen({ diagnosis, onBack, onNewDiagnosis }: Props) {
  const { result } = diagnosis
  const severity = SEVERITY_CONFIG[result.severity]

  return (
    <div style={{
      height: '100%',
      overflow: 'auto',
      display: 'flex',
      flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        display: 'flex',
        alignItems: 'center',
        padding: '16px 20px',
        paddingTop: 'max(16px, env(safe-area-inset-top))',
        borderBottom: '1px solid var(--border)',
        background: 'var(--bg-secondary)',
        position: 'sticky',
        top: 0,
        zIndex: 10,
        gap: 12,
      }}>
        <button
          onClick={onBack}
          style={{
            background: 'none',
            color: 'var(--text-secondary)',
            fontSize: 24,
            padding: '4px 8px 4px 0',
            flexShrink: 0,
          }}
        >
          ←
        </button>
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 style={{ fontSize: 17, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            Diagnosis Results
          </h1>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1 }}>
            {formatDate(diagnosis.timestamp)}
          </p>
        </div>
      </div>

      <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 14 }}>

        {/* Photo if any */}
        {diagnosis.photoBase64 && (
          <div className="animate-fade-in">
            <img
              src={`data:${diagnosis.photoMediaType};base64,${diagnosis.photoBase64}`}
              alt="Problem"
              style={{
                width: '100%',
                maxHeight: 180,
                objectFit: 'cover',
                borderRadius: 'var(--radius)',
                border: '1px solid var(--border)',
              }}
            />
          </div>
        )}

        {/* Problem description */}
        {diagnosis.problemDescription && (
          <div style={{
            padding: '12px 14px',
            background: 'var(--bg-card)',
            borderRadius: 'var(--radius)',
            border: '1px solid var(--border)',
          }} className="animate-fade-in">
            <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 600 }}>Your Problem</p>
            <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.5 }}>{diagnosis.problemDescription}</p>
          </div>
        )}

        {/* Severity badge */}
        <div style={{
          padding: '14px 16px',
          background: severity.bg,
          border: `1px solid ${severity.border}`,
          borderRadius: 'var(--radius)',
          display: 'flex',
          alignItems: 'center',
          gap: 10,
        }} className="animate-slide-up">
          <span style={{ fontSize: 24 }}>{severity.icon}</span>
          <div>
            <div style={{ fontSize: 15, fontWeight: 700, color: severity.color }}>{severity.label}</div>
            <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 2 }}>{result.severityExplanation}</div>
          </div>
        </div>

        {/* What's wrong */}
        <Card icon="🔍" title="What's Wrong" animDelay="0.1s">
          <p style={{ fontSize: 15, lineHeight: 1.6, color: 'var(--text-secondary)' }}>{result.whatIsWrong}</p>
        </Card>

        {/* DIY or Contractor */}
        <Card
          icon={result.isDIY ? '🔨' : '👷'}
          title={result.isDIY ? 'You Can Fix This!' : 'Call a Contractor'}
          animDelay="0.15s"
          accent={result.isDIY ? 'var(--green)' : 'var(--orange)'}
        >
          {result.isDIY && result.diySteps && (
            <ol style={{ paddingLeft: 18, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {result.diySteps.map((step, i) => (
                <li key={i} style={{ fontSize: 14, lineHeight: 1.6, color: 'var(--text-secondary)' }}>
                  {step}
                </li>
              ))}
            </ol>
          )}
          {!result.isDIY && result.contractorType && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 6,
                padding: '6px 12px',
                background: 'var(--orange-glow)',
                borderRadius: 20,
                color: 'var(--orange-light)',
                fontSize: 13,
                fontWeight: 600,
                alignSelf: 'flex-start',
              }}>
                📞 {result.contractorType}
              </div>
              {result.contractorNotes && (
                <p style={{ fontSize: 13, lineHeight: 1.6, color: 'var(--text-secondary)' }}>
                  {result.contractorNotes}
                </p>
              )}
            </div>
          )}
        </Card>

        {/* Cost estimate */}
        <Card icon="💰" title="Estimated Cost" animDelay="0.2s">
          <p style={{ fontSize: 16, fontWeight: 600, color: 'var(--text-primary)' }}>{result.estimatedCost}</p>
        </Card>

        {/* Actions */}
        <div style={{ display: 'flex', gap: 10, marginTop: 4, paddingBottom: 24 }}>
          <button
            onClick={onNewDiagnosis}
            style={{
              flex: 1,
              padding: '14px',
              background: 'linear-gradient(135deg, var(--orange) 0%, var(--orange-dark) 100%)',
              borderRadius: 'var(--radius)',
              color: '#fff',
              fontSize: 15,
              fontWeight: 700,
              boxShadow: '0 4px 16px rgba(249,115,22,0.3)',
            }}
          >
            🔍 New Diagnosis
          </button>
          <button
            onClick={() => {
              const text = [
                `FixIt Diagnosis — ${formatDate(diagnosis.timestamp)}`,
                '',
                `Problem: ${diagnosis.problemDescription}`,
                '',
                `Severity: ${result.severity.toUpperCase()}`,
                result.severityExplanation,
                '',
                `What's Wrong:`,
                result.whatIsWrong,
                '',
                result.isDIY
                  ? `DIY Steps:\n${result.diySteps?.map((s, i) => `${i + 1}. ${s}`).join('\n')}`
                  : `Contractor: ${result.contractorType}\n${result.contractorNotes}`,
                '',
                `Cost Estimate: ${result.estimatedCost}`,
              ].join('\n')

              navigator.share?.({ title: 'FixIt Diagnosis', text })
                ?? navigator.clipboard?.writeText(text)
            }}
            style={{
              padding: '14px 16px',
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius)',
              color: 'var(--text-secondary)',
              fontSize: 15,
            }}
            title="Share"
          >
            🔗
          </button>
        </div>
      </div>
    </div>
  )
}

function Card({
  icon, title, children, animDelay, accent,
}: {
  icon: string
  title: string
  children: React.ReactNode
  animDelay?: string
  accent?: string
}) {
  return (
    <div
      className="animate-slide-up"
      style={{
        background: 'var(--bg-card)',
        border: `1px solid ${accent ? `${accent}40` : 'var(--border)'}`,
        borderRadius: 'var(--radius)',
        overflow: 'hidden',
        animationDelay: animDelay,
        animationFillMode: 'both',
      }}
    >
      <div style={{
        padding: '10px 14px',
        borderBottom: '1px solid var(--border)',
        display: 'flex',
        alignItems: 'center',
        gap: 6,
        background: accent ? `${accent}10` : 'transparent',
      }}>
        <span style={{ fontSize: 16 }}>{icon}</span>
        <span style={{
          fontSize: 12,
          fontWeight: 700,
          textTransform: 'uppercase',
          letterSpacing: '0.07em',
          color: accent ?? 'var(--text-muted)',
        }}>
          {title}
        </span>
      </div>
      <div style={{ padding: '14px' }}>
        {children}
      </div>
    </div>
  )
}
