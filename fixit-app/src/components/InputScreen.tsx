import { useState, useRef } from 'react'
import type { Diagnosis } from '../types'
import { diagnoseProblem } from '../api'

interface Props {
  onComplete: (diagnosis: Diagnosis) => void
  onBack: () => void
}

const SUGGESTIONS = [
  'Mancha de agua en el techo', 'Grietas en la pared', 'Enchufe sin corriente',
  'Grifo que gotea', 'Puerta que no cierra', 'Humedad en la pared',
]

export default function InputScreen({ onComplete, onBack }: Props) {
  const [description, setDescription] = useState('')
  const [photo, setPhoto] = useState<{ base64: string; mediaType: string; preview: string } | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [dragOver, setDragOver] = useState(false)
  const fileRef = useRef<HTMLInputElement>(null)
  const canSubmit = description.trim() || photo

  const processFile = (file: File) => {
    if (!file.type.startsWith('image/')) { setError('Por favor selecciona una imagen.'); return }
    if (file.size > 5 * 1024 * 1024) { setError('La imagen debe ser menor de 5MB.'); return }
    const reader = new FileReader()
    reader.onload = ev => {
      const dataUrl = ev.target?.result as string
      setPhoto({ base64: dataUrl.split(',')[1], mediaType: file.type, preview: dataUrl })
      setError('')
    }
    reader.readAsDataURL(file)
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) processFile(file)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault(); setDragOver(false)
    const file = e.dataTransfer.files?.[0]
    if (file) processFile(file)
  }

  const handleSubmit = async () => {
    if (!canSubmit) return
    const apiKey = localStorage.getItem('fixit_api_key')
    if (!apiKey) { setError('Sin clave API. Ve a Ajustes para añadirla.'); return }

    setLoading(true); setError('')
    try {
      const result = await diagnoseProblem(apiKey, description.trim(), photo?.base64, photo?.mediaType)
      const diagnosis: Diagnosis = {
        id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
        timestamp: Date.now(),
        problemDescription: description.trim() || 'Análisis de foto',
        photoBase64: photo?.base64,
        photoMediaType: photo?.mediaType,
        result,
      }
      onComplete(diagnosis)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Error desconocido'
      if (msg.includes('401') || msg.includes('auth')) setError('Clave API inválida. Revísala en Ajustes.')
      else if (msg.includes('network') || msg.includes('fetch')) setError('Sin conexión. Verifica tu internet.')
      else setError(msg || 'Error al diagnosticar. Inténtalo de nuevo.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{
      height: '100%', overflow: 'auto',
      display: 'flex', flexDirection: 'column',
      position: 'relative',
    }}>
      {/* Ambient */}
      <div style={{
        position: 'absolute', top: -40, left: -60, width: 200, height: 200,
        background: 'radial-gradient(circle, rgba(99,102,241,0.12) 0%, transparent 70%)',
        borderRadius: '50%', pointerEvents: 'none',
        animation: 'orb-drift2 12s ease-in-out infinite',
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
            borderRadius: 12,
            color: 'var(--text-secondary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 18, flexShrink: 0,
          }}
        >
          ←
        </button>
        <div>
          <h1 style={{ fontSize: 17, fontWeight: 800, letterSpacing: '-0.02em' }}>Nuevo Diagnóstico</h1>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 1 }}>
            Describe el problema o sube una foto
          </p>
        </div>
      </div>

      <div style={{ flex: 1, padding: '20px 18px', display: 'flex', flexDirection: 'column', gap: 18, position: 'relative', zIndex: 1 }}>

        {/* Photo Zone */}
        <div className="anim-fade-up">
          <label style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', display: 'block', marginBottom: 10, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
            Foto del Problema <span style={{ color: 'var(--text-muted)', fontWeight: 400, textTransform: 'none', letterSpacing: 0 }}>— Opcional</span>
          </label>

          {photo ? (
            <div style={{ position: 'relative', borderRadius: 'var(--radius-lg)', overflow: 'hidden', border: '1px solid var(--border-light)' }}>
              <img
                src={photo.preview} alt="Problema"
                style={{ width: '100%', maxHeight: 200, objectFit: 'cover', display: 'block' }}
              />
              <div style={{
                position: 'absolute', inset: 0,
                background: 'linear-gradient(to top, rgba(0,0,0,0.5) 0%, transparent 50%)',
              }} />
              <button
                onClick={() => setPhoto(null)}
                style={{
                  position: 'absolute', top: 10, right: 10,
                  width: 32, height: 32,
                  background: 'rgba(0,0,0,0.6)',
                  backdropFilter: 'blur(8px)',
                  borderRadius: 10, color: '#fff', fontSize: 16,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  border: '1px solid rgba(255,255,255,0.1)',
                }}
              >×</button>
              <div style={{
                position: 'absolute', bottom: 10, left: 12,
                fontSize: 12, color: 'rgba(255,255,255,0.8)', fontWeight: 600,
                display: 'flex', alignItems: 'center', gap: 4,
              }}>
                <span style={{ fontSize: 14 }}>✅</span> Foto añadida
              </div>
            </div>
          ) : (
            <div
              onClick={() => fileRef.current?.click()}
              onDragOver={e => { e.preventDefault(); setDragOver(true) }}
              onDragLeave={() => setDragOver(false)}
              onDrop={handleDrop}
              style={{
                padding: '28px 20px',
                background: dragOver
                  ? 'linear-gradient(135deg, rgba(249,115,22,0.1) 0%, rgba(245,158,11,0.06) 100%)'
                  : 'var(--grad-card)',
                border: `2px dashed ${dragOver ? 'var(--orange)' : 'rgba(255,255,255,0.1)'}`,
                borderRadius: 'var(--radius-lg)',
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
                cursor: 'pointer',
                transition: 'all var(--transition)',
              }}
            >
              <div style={{
                width: 52, height: 52,
                background: 'linear-gradient(135deg, rgba(249,115,22,0.15) 0%, rgba(245,158,11,0.08) 100%)',
                border: '1px solid rgba(249,115,22,0.25)',
                borderRadius: 16,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24,
              }}>📷</div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 3 }}>
                  {dragOver ? 'Suelta la imagen aquí' : 'Toca para añadir foto'}
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                  JPG, PNG, WEBP — Máximo 5MB
                </div>
              </div>
            </div>
          )}
          <input ref={fileRef} type="file" accept="image/*" capture="environment" onChange={handleFileChange} style={{ display: 'none' }} />
        </div>

        {/* Description */}
        <div style={{ flex: 1, animation: 'fadeUp 0.4s 0.1s ease both' }}>
          <label style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', display: 'block', marginBottom: 10, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
            Descripción del Problema
          </label>
          <div style={{
            borderRadius: 'var(--radius-lg)',
            background: 'var(--bg-input)',
            border: '1px solid var(--border)',
            transition: 'border-color var(--transition)',
            overflow: 'hidden',
          }}>
            <textarea
              value={description}
              onChange={e => setDescription(e.target.value)}
              placeholder="Ej: 'Hay una mancha marrón en el techo del baño que se está agrandando. El suelo de arriba es la cocina. El techo no tiene grietas pero se ve húmedo...'"
              rows={5}
              style={{
                width: '100%', padding: '14px 14px 10px',
                background: 'transparent',
                color: 'var(--text-primary)',
                fontSize: 15, lineHeight: 1.65, resize: 'none',
                border: 'none',
              }}
              onFocus={e => { (e.currentTarget.closest('div') as HTMLElement).style.borderColor = 'var(--orange)' }}
              onBlur={e => { (e.currentTarget.closest('div') as HTMLElement).style.borderColor = 'var(--border)' }}
            />
            {/* Char counter */}
            <div style={{
              padding: '6px 14px', borderTop: '1px solid var(--border)',
              display: 'flex', justifyContent: 'flex-end',
            }}>
              <span style={{ fontSize: 11, color: description.length > 500 ? 'var(--orange)' : 'var(--text-muted)' }}>
                {description.length} caracteres
              </span>
            </div>
          </div>
        </div>

        {/* Quick suggestions */}
        <div style={{ animation: 'fadeUp 0.4s 0.15s ease both' }}>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
            Ejemplos rápidos
          </p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {SUGGESTIONS.map(s => (
              <button
                key={s}
                onClick={() => setDescription(s)}
                style={{
                  padding: '6px 12px',
                  background: description === s ? 'var(--orange-dim)' : 'var(--bg-card)',
                  border: `1px solid ${description === s ? 'rgba(249,115,22,0.3)' : 'var(--border)'}`,
                  borderRadius: 'var(--radius-full)',
                  color: description === s ? 'var(--orange-light)' : 'var(--text-secondary)',
                  fontSize: 12, fontWeight: 500,
                  transition: 'all var(--transition)',
                }}
              >{s}</button>
            ))}
          </div>
        </div>

        {/* Error */}
        {error && (
          <div style={{
            padding: '12px 14px',
            background: 'var(--red-dim)',
            border: '1px solid rgba(239,68,68,0.25)',
            borderRadius: 'var(--radius)',
            color: 'var(--red-light)', fontSize: 13, lineHeight: 1.5,
            display: 'flex', gap: 8, alignItems: 'flex-start',
          }} className="anim-scale-in">
            <span>⚠️</span><span>{error}</span>
          </div>
        )}

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={loading || !canSubmit}
          style={{
            width: '100%', padding: '17px',
            background: loading || !canSubmit
              ? 'rgba(255,255,255,0.04)'
              : 'var(--grad-brand)',
            border: loading || !canSubmit ? '1px solid var(--border)' : 'none',
            borderRadius: 'var(--radius-lg)',
            color: loading || !canSubmit ? 'var(--text-muted)' : '#fff',
            fontSize: 16, fontWeight: 800, letterSpacing: '-0.01em',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
            boxShadow: !loading && canSubmit ? 'var(--shadow-orange)' : 'none',
            transition: 'all var(--transition)',
            animation: 'fadeUp 0.4s 0.2s ease both',
          }}
        >
          {loading ? (
            <>
              <span style={{
                width: 20, height: 20,
                border: '2.5px solid rgba(255,255,255,0.2)',
                borderTopColor: '#fff',
                borderRadius: '50%',
                animation: 'spin 0.7s linear infinite', display: 'inline-block',
              }} />
              <span>Analizando con IA...</span>
              <LoadingDots />
            </>
          ) : (
            <>
              <span style={{ fontSize: 20 }}>🔍</span>
              <span>Diagnosticar Ahora</span>
            </>
          )}
        </button>

        <div style={{ height: 8 }} />
      </div>
    </div>
  )
}

function LoadingDots() {
  return (
    <span style={{ display: 'flex', gap: 3, alignItems: 'center' }}>
      {[0, 1, 2].map(i => (
        <span key={i} style={{
          width: 4, height: 4, borderRadius: '50%',
          background: 'rgba(255,255,255,0.6)',
          animation: `dot-bounce 1.2s ${i * 0.2}s ease-in-out infinite`,
          display: 'inline-block',
        }} />
      ))}
    </span>
  )
}
