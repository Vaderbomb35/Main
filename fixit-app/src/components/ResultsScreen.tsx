import { useState } from 'react'
import type { Diagnosis, SeverityLevel } from '../types'

interface Props {
  diagnosis: Diagnosis
  onBack: () => void
  onNewDiagnosis: () => void
}

const SEV = {
  low: {
    label: 'Baja Gravedad',
    sublabel: 'Sin urgencia',
    color: '#10b981',
    colorLight: '#34d399',
    dim: 'rgba(16,185,129,0.1)',
    glow: 'rgba(16,185,129,0.3)',
    border: 'rgba(16,185,129,0.25)',
    emoji: '🟢',
    icon: '✅',
    gradient: 'linear-gradient(135deg, rgba(16,185,129,0.15) 0%, rgba(5,150,105,0.08) 100%)',
  },
  medium: {
    label: 'Gravedad Media',
    sublabel: 'Atender pronto',
    color: '#f59e0b',
    colorLight: '#fcd34d',
    dim: 'rgba(245,158,11,0.1)',
    glow: 'rgba(245,158,11,0.3)',
    border: 'rgba(245,158,11,0.25)',
    emoji: '🟡',
    icon: '⚠️',
    gradient: 'linear-gradient(135deg, rgba(245,158,11,0.15) 0%, rgba(217,119,6,0.08) 100%)',
  },
  high: {
    label: 'Alta Gravedad',
    sublabel: 'Urgente — actúa ya',
    color: '#ef4444',
    colorLight: '#f87171',
    dim: 'rgba(239,68,68,0.1)',
    glow: 'rgba(239,68,68,0.4)',
    border: 'rgba(239,68,68,0.3)',
    emoji: '🔴',
    icon: '🚨',
    gradient: 'linear-gradient(135deg, rgba(239,68,68,0.15) 0%, rgba(185,28,28,0.08) 100%)',
  },
}

function formatDate(ts: number) {
  return new Date(ts).toLocaleDateString('es-ES', {
    day: 'numeric', month: 'long', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export default function ResultsScreen({ diagnosis, onBack, onNewDiagnosis }: Props) {
  const { result } = diagnosis
  const s = SEV[result.severity as SeverityLevel]
  const [shared, setShared] = useState(false)

  const handleShare = async () => {
    const text = [
      `🔧 FixIt — Diagnóstico`,
      `📅 ${formatDate(diagnosis.timestamp)}`,
      ``,
      `Problema: ${diagnosis.problemDescription}`,
      `Gravedad: ${s.label}`,
      ``,
      result.whatIsWrong,
      ``,
      result.isDIY
        ? `🔨 PUEDES REPARARLO TÚ:\n${result.diySteps?.map((step, i) => `${i + 1}. ${step}`).join('\n')}`
        : `👷 LLAMA A: ${result.contractorType}\n${result.contractorNotes}`,
      ``,
      `💰 Coste estimado: ${result.estimatedCost}`,
    ].join('\n')

    try {
      if (navigator.share) await navigator.share({ title: 'FixIt — Diagnóstico', text })
      else await navigator.clipboard.writeText(text)
      setShared(true); setTimeout(() => setShared(false), 2500)
    } catch {}
  }

  return (
    <div style={{
      height: '100%', overflow: 'auto',
      display: 'flex', flexDirection: 'column',
      position: 'relative',
    }}>
      {/* Severity ambient glow */}
      <div style={{
        position: 'absolute', top: -80, right: -60, width: 240, height: 240,
        background: `radial-gradient(circle, ${s.glow} 0%, transparent 70%)`,
        borderRadius: '50%', pointerEvents: 'none',
        animation: 'orb-drift 10s ease-in-out infinite',
      }} />

      {/* Header */}
      <div style={{
        position: 'sticky', top: 0, zIndex: 20,
        background: 'rgba(8,12,20,0.9)',
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid var(--border)',
        padding: '14px 18px',
        paddingTop: 'max(14px, env(safe-area-inset-top))',
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <button
          onClick={onBack}
          style={{
            width: 36, height: 36,
            background: 'var(--bg-card)',
            border: '1px solid var(--border-light)',
            borderRadius: 12, color: 'var(--text-secondary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18,
          }}
        >←</button>
        <div style={{ flex: 1, minWidth: 0 }}>
          <h1 style={{ fontSize: 17, fontWeight: 800, letterSpacing: '-0.02em' }}>Resultado del Diagnóstico</h1>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {formatDate(diagnosis.timestamp)}
          </p>
        </div>
        <button
          onClick={handleShare}
          style={{
            width: 36, height: 36,
            background: shared ? 'var(--green-dim)' : 'var(--bg-card)',
            border: `1px solid ${shared ? 'rgba(16,185,129,0.3)' : 'var(--border-light)'}`,
            borderRadius: 12, color: shared ? 'var(--green)' : 'var(--text-secondary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16,
            transition: 'all var(--transition)',
          }}
          title="Compartir"
        >{shared ? '✓' : '↗'}</button>
      </div>

      <div style={{ padding: '16px 18px', display: 'flex', flexDirection: 'column', gap: 14, position: 'relative', zIndex: 1 }}>

        {/* Photo */}
        {diagnosis.photoBase64 && (
          <div style={{ borderRadius: 'var(--radius-lg)', overflow: 'hidden', border: '1px solid var(--border)', position: 'relative' }} className="anim-fade">
            <img
              src={`data:${diagnosis.photoMediaType};base64,${diagnosis.photoBase64}`}
              alt="Problema"
              style={{ width: '100%', maxHeight: 190, objectFit: 'cover', display: 'block' }}
            />
            <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(0,0,0,0.4) 0%, transparent 50%)' }} />
          </div>
        )}

        {/* Problem description */}
        {diagnosis.problemDescription && diagnosis.problemDescription !== 'Análisis de foto' && (
          <div style={{
            padding: '11px 14px',
            background: 'var(--grad-card)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius)',
          }} className="anim-fade-up">
            <p style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.07em', fontWeight: 700 }}>Tu consulta</p>
            <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.55, fontStyle: 'italic' }}>"{diagnosis.problemDescription}"</p>
          </div>
        )}

        {/* SEVERITY CARD — Hero */}
        <div style={{
          padding: '20px',
          background: s.gradient,
          border: `1px solid ${s.border}`,
          borderRadius: 'var(--radius-lg)',
          position: 'relative', overflow: 'hidden',
          animation: 'scaleIn 0.4s cubic-bezier(0.34,1.56,0.64,1) both',
        }}>
          <div style={{
            position: 'absolute', top: -20, right: -20, width: 100, height: 100,
            background: `radial-gradient(circle, ${s.glow} 0%, transparent 70%)`,
            borderRadius: '50%',
          }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, position: 'relative' }}>
            <div style={{
              width: 52, height: 52,
              background: `${s.dim}`,
              border: `2px solid ${s.border}`,
              borderRadius: 16,
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 26,
              boxShadow: `0 4px 20px ${s.glow}`,
            }}>
              {s.icon}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 900, color: s.colorLight, letterSpacing: '-0.02em' }}>{s.label}</div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.55)', marginTop: 2 }}>{s.sublabel}</div>
            </div>
            <div style={{
              padding: '6px 14px',
              background: `${s.dim}`,
              border: `1px solid ${s.border}`,
              borderRadius: 'var(--radius-full)',
              fontSize: 22,
              animation: 'badge-pop 0.5s 0.2s cubic-bezier(0.34,1.56,0.64,1) both',
            }}>
              {s.emoji}
            </div>
          </div>
          {/* Severity bar */}
          <div style={{ marginTop: 14, height: 4, background: 'rgba(255,255,255,0.1)', borderRadius: 2, overflow: 'hidden' }}>
            <div style={{
              height: '100%',
              width: result.severity === 'low' ? '33%' : result.severity === 'medium' ? '66%' : '100%',
              background: `linear-gradient(90deg, ${s.color}, ${s.colorLight})`,
              borderRadius: 2,
              animation: 'line-grow 0.8s 0.3s ease both',
            }} />
          </div>
          <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.6)', marginTop: 10, lineHeight: 1.5 }}>
            {result.severityExplanation}
          </p>
        </div>

        {/* What's wrong */}
        <ResultCard
          icon="🔬"
          title="¿Qué está pasando?"
          delay="0.1s"
          accentColor="#6366f1"
        >
          <p style={{ fontSize: 15, lineHeight: 1.7, color: 'var(--text-secondary)' }}>{result.whatIsWrong}</p>
        </ResultCard>

        {/* DIY / Contractor */}
        <ResultCard
          icon={result.isDIY ? '🔨' : '👷'}
          title={result.isDIY ? 'Puedes repararlo tú mismo' : 'Necesitas un profesional'}
          delay="0.15s"
          accentColor={result.isDIY ? '#10b981' : '#f97316'}
          badge={result.isDIY ? { label: 'DIY', color: '#10b981' } : { label: 'PROFESIONAL', color: '#f97316' }}
        >
          {result.isDIY && result.diySteps ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {result.diySteps.map((step, i) => (
                <div key={i} style={{
                  display: 'flex', gap: 12, alignItems: 'flex-start',
                  padding: '11px 12px',
                  background: 'rgba(16,185,129,0.05)',
                  border: '1px solid rgba(16,185,129,0.12)',
                  borderRadius: 'var(--radius)',
                  animation: `fadeUp 0.35s ${0.1 + i * 0.07}s ease both`,
                }}>
                  <div style={{
                    width: 26, height: 26, flexShrink: 0,
                    background: 'rgba(16,185,129,0.15)',
                    border: '1px solid rgba(16,185,129,0.3)',
                    borderRadius: 8,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 12, fontWeight: 800, color: '#34d399',
                  }}>{i + 1}</div>
                  <span style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--text-secondary)', paddingTop: 3 }}>{step}</span>
                </div>
              ))}
            </div>
          ) : !result.isDIY && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{
                padding: '14px',
                background: 'rgba(249,115,22,0.06)',
                border: '1px solid rgba(249,115,22,0.2)',
                borderRadius: 'var(--radius)',
                display: 'flex', alignItems: 'center', gap: 10,
              }}>
                <span style={{ fontSize: 24 }}>📞</span>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.07em', fontWeight: 700, marginBottom: 2 }}>
                    Especialista recomendado
                  </div>
                  <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--orange-light)' }}>
                    {result.contractorType}
                  </div>
                </div>
              </div>
              {result.contractorNotes && (
                <p style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.6, paddingLeft: 4 }}>
                  💡 {result.contractorNotes}
                </p>
              )}
            </div>
          )}
        </ResultCard>

        {/* Cost */}
        <ResultCard
          icon="💰"
          title="Coste Estimado"
          delay="0.2s"
          accentColor="#fbbf24"
        >
          <div style={{
            fontSize: 20, fontWeight: 900, letterSpacing: '-0.03em',
            background: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
            lineHeight: 1.2,
          }}>
            {result.estimatedCost}
          </div>
        </ResultCard>

        {/* Actions */}
        <div style={{ display: 'flex', gap: 10, paddingBottom: 8, animation: 'fadeUp 0.4s 0.3s ease both' }}>
          <button
            onClick={onNewDiagnosis}
            className="btn-primary"
            style={{
              flex: 1, padding: '15px',
              borderRadius: 'var(--radius-lg)',
              fontSize: 15, fontWeight: 800,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            <span>🔍</span> Nuevo Diagnóstico
          </button>
          <button
            onClick={handleShare}
            className="btn-ghost"
            style={{
              padding: '15px 18px',
              borderRadius: 'var(--radius-lg)', fontSize: 15,
              background: shared ? 'var(--green-dim)' : undefined,
              color: shared ? 'var(--green)' : undefined,
              borderColor: shared ? 'rgba(16,185,129,0.3)' : undefined,
            }}
          >
            {shared ? '✓' : '↗'}
          </button>
        </div>

        <div style={{ height: 12 }} />
      </div>
    </div>
  )
}

function ResultCard({
  icon, title, children, delay, accentColor, badge,
}: {
  icon: string
  title: string
  children: React.ReactNode
  delay?: string
  accentColor?: string
  badge?: { label: string; color: string }
}) {
  const accent = accentColor ?? 'var(--orange)'
  return (
    <div
      className="anim-fade-up"
      style={{
        background: 'var(--grad-card)',
        border: `1px solid ${accent}25`,
        borderRadius: 'var(--radius-lg)',
        overflow: 'hidden',
        animationDelay: delay,
        animationFillMode: 'both',
        backdropFilter: 'blur(10px)',
      }}
    >
      <div style={{
        padding: '12px 14px',
        borderBottom: '1px solid var(--border)',
        background: `${accent}08`,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span style={{ fontSize: 18 }}>{icon}</span>
        <span style={{
          flex: 1, fontSize: 12, fontWeight: 800, letterSpacing: '0.07em',
          textTransform: 'uppercase', color: accent,
        }}>{title}</span>
        {badge && (
          <span style={{
            padding: '3px 9px',
            background: `${badge.color}15`,
            border: `1px solid ${badge.color}35`,
            borderRadius: 'var(--radius-full)',
            fontSize: 10, fontWeight: 800, color: badge.color, letterSpacing: '0.06em',
          }}>{badge.label}</span>
        )}
      </div>
      <div style={{ padding: '14px' }}>{children}</div>
    </div>
  )
}
