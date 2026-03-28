import type { Diagnosis, SeverityLevel } from '../types'

interface Props {
  history: Diagnosis[]
  onView: (d: Diagnosis) => void
  onDelete: (id: string) => void
  onClear: () => void
}

const SEV_COLOR: Record<SeverityLevel, string> = {
  low: '#10b981',
  medium: '#f59e0b',
  high: '#ef4444',
}
const SEV_LABEL: Record<SeverityLevel, string> = {
  low: 'Baja',
  medium: 'Media',
  high: 'Alta',
}

function relativeTime(ts: number) {
  const d = Date.now() - ts
  if (d < 60000) return 'Ahora mismo'
  if (d < 3600000) return `Hace ${Math.floor(d / 60000)} min`
  if (d < 86400000) return `Hace ${Math.floor(d / 3600000)} h`
  if (d < 604800000) return `Hace ${Math.floor(d / 86400000)} días`
  return new Date(ts).toLocaleDateString('es-ES', { day: 'numeric', month: 'short' })
}

function truncate(s: string, n: number) {
  return s.length > n ? s.slice(0, n) + '…' : s
}

export default function HistoryScreen({ history, onView, onDelete, onClear }: Props) {
  const highCount = history.filter(d => d.result.severity === 'high').length
  const diyCount = history.filter(d => d.result.isDIY).length

  return (
    <div style={{ height: '100%', overflow: 'auto', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{
        padding: '16px 18px',
        paddingTop: 'max(16px, env(safe-area-inset-top))',
        borderBottom: '1px solid var(--border)',
        background: 'rgba(8,12,20,0.9)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        position: 'sticky', top: 0, zIndex: 20,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <h1 style={{ fontSize: 22, fontWeight: 900, letterSpacing: '-0.03em' }}>Historial</h1>
            {history.length > 0 && (
              <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>
                {history.length} diagnóstico{history.length !== 1 ? 's' : ''} guardados
              </p>
            )}
          </div>
          {history.length > 0 && (
            <button
              onClick={() => { if (window.confirm('¿Borrar todo el historial?')) onClear() }}
              style={{
                padding: '6px 12px',
                background: 'rgba(239,68,68,0.08)',
                border: '1px solid rgba(239,68,68,0.2)',
                borderRadius: 'var(--radius-full)',
                color: 'var(--red)',
                fontSize: 12, fontWeight: 600,
              }}
            >Borrar todo</button>
          )}
        </div>

        {/* Stats bar */}
        {history.length > 1 && (
          <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
            {[
              { label: 'Total', value: history.length, color: 'var(--orange)' },
              { label: 'Urgentes', value: highCount, color: 'var(--red)' },
              { label: 'DIY', value: diyCount, color: 'var(--green)' },
            ].map(stat => (
              <div key={stat.label} style={{
                flex: 1, padding: '8px 10px', textAlign: 'center',
                background: 'var(--grad-card)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius)',
              }}>
                <div style={{
                  fontSize: 18, fontWeight: 900, letterSpacing: '-0.03em', color: stat.color,
                  lineHeight: 1,
                }}>{stat.value}</div>
                <div style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 2, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.06em' }}>{stat.label}</div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Empty state */}
      {history.length === 0 ? (
        <div style={{
          flex: 1, display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center',
          gap: 14, padding: '40px 24px',
          animation: 'fadeUp 0.4s ease both',
        }}>
          <div style={{
            width: 80, height: 80,
            background: 'var(--grad-card)',
            border: '1px solid var(--border)',
            borderRadius: 24,
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 36,
          }}>📋</div>
          <div style={{ textAlign: 'center' }}>
            <p style={{ fontSize: 17, fontWeight: 800, marginBottom: 6 }}>Sin diagnósticos aún</p>
            <p style={{ fontSize: 14, color: 'var(--text-muted)', lineHeight: 1.5 }}>
              Tus diagnósticos anteriores<br />aparecerán aquí
            </p>
          </div>
        </div>
      ) : (
        <div style={{ padding: '14px 18px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {history.map((item, i) => {
            const color = SEV_COLOR[item.result.severity as SeverityLevel]
            return (
              <div
                key={item.id}
                className="anim-fade-up"
                style={{
                  animationDelay: `${i * 0.04}s`, animationFillMode: 'both',
                  background: 'var(--grad-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-lg)',
                  overflow: 'hidden',
                  position: 'relative',
                  transition: 'border-color var(--transition)',
                }}
              >
                {/* Severity stripe */}
                <div style={{
                  position: 'absolute', left: 0, top: 0, bottom: 0, width: 3,
                  background: `linear-gradient(180deg, ${color} 0%, ${color}60 100%)`,
                }} />

                <div style={{ display: 'flex', alignItems: 'stretch' }}>
                  {/* Main tap area */}
                  <button
                    onClick={() => onView(item)}
                    style={{
                      flex: 1, background: 'none', padding: '13px 12px 13px 16px',
                      textAlign: 'left', display: 'flex', gap: 11, alignItems: 'flex-start',
                      minWidth: 0,
                    }}
                  >
                    {/* Photo thumb */}
                    {item.photoBase64 ? (
                      <img
                        src={`data:${item.photoMediaType};base64,${item.photoBase64}`}
                        alt=""
                        style={{
                          width: 54, height: 54, objectFit: 'cover',
                          borderRadius: 12, flexShrink: 0,
                          border: '1px solid var(--border)',
                        }}
                      />
                    ) : (
                      <div style={{
                        width: 54, height: 54, flexShrink: 0,
                        background: `${color}10`,
                        border: `1px solid ${color}25`,
                        borderRadius: 12,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 24,
                      }}>
                        {item.result.isDIY ? '🔨' : '👷'}
                      </div>
                    )}

                    {/* Text */}
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6, alignItems: 'flex-start', marginBottom: 4 }}>
                        <p style={{
                          fontSize: 14, fontWeight: 700, lineHeight: 1.3,
                          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flex: 1,
                        }}>
                          {truncate(item.problemDescription || 'Análisis de foto', 40)}
                        </p>
                        <span style={{ fontSize: 11, color: 'var(--text-muted)', flexShrink: 0 }}>
                          {relativeTime(item.timestamp)}
                        </span>
                      </div>
                      <p style={{ fontSize: 12, color: 'var(--text-muted)', lineHeight: 1.45, marginBottom: 7 }}>
                        {truncate(item.result.whatIsWrong, 65)}
                      </p>
                      <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
                        {/* Severity pill */}
                        <span style={{
                          padding: '3px 8px',
                          background: `${color}12`,
                          border: `1px solid ${color}28`,
                          borderRadius: 'var(--radius-full)',
                          fontSize: 10, fontWeight: 700, color,
                          letterSpacing: '0.04em',
                        }}>
                          ● {SEV_LABEL[item.result.severity as SeverityLevel]}
                        </span>
                        {/* DIY/Pro pill */}
                        <span style={{
                          padding: '3px 8px',
                          background: item.result.isDIY ? 'rgba(16,185,129,0.08)' : 'rgba(249,115,22,0.08)',
                          border: `1px solid ${item.result.isDIY ? 'rgba(16,185,129,0.2)' : 'rgba(249,115,22,0.2)'}`,
                          borderRadius: 'var(--radius-full)',
                          fontSize: 10, fontWeight: 700,
                          color: item.result.isDIY ? 'var(--green)' : 'var(--orange)',
                          letterSpacing: '0.04em',
                        }}>
                          {item.result.isDIY ? '🔨 DIY' : '👷 Pro'}
                        </span>
                      </div>
                    </div>
                  </button>

                  {/* Delete */}
                  <button
                    onClick={() => onDelete(item.id)}
                    style={{
                      padding: '0 14px',
                      background: 'none', color: 'var(--text-muted)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 17, flexShrink: 0,
                      borderLeft: '1px solid var(--border)',
                      transition: 'color var(--transition)',
                    }}
                    title="Eliminar"
                  >🗑</button>
                </div>
              </div>
            )
          })}
          <div style={{ height: 16 }} />
        </div>
      )}
    </div>
  )
}
