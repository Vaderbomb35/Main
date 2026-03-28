import type { Diagnosis, SeverityLevel } from '../types'

interface Props {
  history: Diagnosis[]
  onView: (d: Diagnosis) => void
  onDelete: (id: string) => void
  onClear: () => void
}

const SEVERITY_DOT: Record<SeverityLevel, string> = {
  low: '#22c55e',
  medium: '#eab308',
  high: '#ef4444',
}

function formatRelativeDate(ts: number) {
  const diff = Date.now() - ts
  const mins = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (mins < 1) return 'Just now'
  if (mins < 60) return `${mins}m ago`
  if (hours < 24) return `${hours}h ago`
  if (days < 7) return `${days}d ago`
  return new Date(ts).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
}

function truncate(str: string, len: number) {
  return str.length > len ? str.slice(0, len) + '…' : str
}

export default function HistoryScreen({ history, onView, onDelete, onClear }: Props) {
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
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}>
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>History</h1>
        {history.length > 0 && (
          <button
            onClick={() => {
              if (confirm('Clear all history?')) onClear()
            }}
            style={{
              background: 'none',
              color: 'var(--text-muted)',
              fontSize: 13,
              padding: '4px 8px',
            }}
          >
            Clear All
          </button>
        )}
      </div>

      {history.length === 0 ? (
        <div style={{
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 12,
          color: 'var(--text-muted)',
          padding: '40px 20px',
        }}>
          <span style={{ fontSize: 48 }}>📋</span>
          <p style={{ fontSize: 16, fontWeight: 600 }}>No diagnoses yet</p>
          <p style={{ fontSize: 14, textAlign: 'center' }}>
            Your past diagnoses will appear here
          </p>
        </div>
      ) : (
        <div style={{ padding: '12px 20px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {history.map((item, i) => (
            <div
              key={item.id}
              className="animate-fade-in"
              style={{
                animationDelay: `${i * 0.05}s`,
                animationFillMode: 'both',
                display: 'flex',
                gap: 0,
                background: 'var(--bg-card)',
                borderRadius: 'var(--radius)',
                border: '1px solid var(--border)',
                overflow: 'hidden',
              }}
            >
              {/* Severity stripe */}
              <div style={{
                width: 4,
                background: SEVERITY_DOT[item.result.severity],
                flexShrink: 0,
              }} />

              {/* Content */}
              <button
                onClick={() => onView(item)}
                style={{
                  flex: 1,
                  background: 'none',
                  padding: '12px 12px',
                  textAlign: 'left',
                  display: 'flex',
                  gap: 10,
                  alignItems: 'flex-start',
                  minWidth: 0,
                }}
              >
                {item.photoBase64 && (
                  <img
                    src={`data:${item.photoMediaType};base64,${item.photoBase64}`}
                    alt=""
                    style={{
                      width: 52,
                      height: 52,
                      objectFit: 'cover',
                      borderRadius: 8,
                      flexShrink: 0,
                      border: '1px solid var(--border)',
                    }}
                  />
                )}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8, marginBottom: 4 }}>
                    <p style={{
                      fontSize: 14,
                      fontWeight: 600,
                      color: 'var(--text-primary)',
                      lineHeight: 1.3,
                      flex: 1,
                    }}>
                      {truncate(item.problemDescription || 'Photo analysis', 52)}
                    </p>
                    <span style={{
                      fontSize: 11,
                      color: 'var(--text-muted)',
                      whiteSpace: 'nowrap',
                      flexShrink: 0,
                    }}>
                      {formatRelativeDate(item.timestamp)}
                    </span>
                  </div>
                  <p style={{ fontSize: 12, color: 'var(--text-muted)', lineHeight: 1.4 }}>
                    {truncate(item.result.whatIsWrong, 70)}
                  </p>
                  <div style={{ display: 'flex', gap: 6, marginTop: 6, alignItems: 'center' }}>
                    <span style={{
                      width: 7,
                      height: 7,
                      borderRadius: '50%',
                      background: SEVERITY_DOT[item.result.severity],
                      display: 'inline-block',
                    }} />
                    <span style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'capitalize' }}>
                      {item.result.severity} severity
                    </span>
                    <span style={{ fontSize: 11, color: 'var(--text-muted)', marginLeft: 4 }}>
                      {item.result.isDIY ? '🔨 DIY' : '👷 Contractor'}
                    </span>
                  </div>
                </div>
              </button>

              {/* Delete button */}
              <button
                onClick={() => onDelete(item.id)}
                style={{
                  background: 'none',
                  color: 'var(--text-muted)',
                  padding: '12px 12px',
                  fontSize: 16,
                  flexShrink: 0,
                  alignSelf: 'stretch',
                  display: 'flex',
                  alignItems: 'center',
                }}
                title="Delete"
              >
                🗑
              </button>
            </div>
          ))}

          <div style={{ height: 16 }} />
        </div>
      )}
    </div>
  )
}
