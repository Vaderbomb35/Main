import { useState, useRef } from 'react'
import type { Diagnosis } from '../types'
import { diagnoseProblem } from '../api'

interface Props {
  onComplete: (diagnosis: Diagnosis) => void
  onBack: () => void
}

export default function InputScreen({ onComplete, onBack }: Props) {
  const [description, setDescription] = useState('')
  const [photo, setPhoto] = useState<{ base64: string; mediaType: string; preview: string } | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const fileRef = useRef<HTMLInputElement>(null)

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    if (!file.type.startsWith('image/')) {
      setError('Please select an image file.')
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      setError('Image must be under 5MB.')
      return
    }

    const reader = new FileReader()
    reader.onload = (event) => {
      const dataUrl = event.target?.result as string
      const base64 = dataUrl.split(',')[1]
      setPhoto({
        base64,
        mediaType: file.type,
        preview: dataUrl,
      })
      setError('')
    }
    reader.readAsDataURL(file)
  }

  const handleSubmit = async () => {
    if (!description.trim() && !photo) {
      setError('Please describe the problem or add a photo.')
      return
    }

    const apiKey = localStorage.getItem('fixit_api_key')
    if (!apiKey) {
      setError('No API key found. Please add your Anthropic API key in Settings.')
      return
    }

    setLoading(true)
    setError('')

    try {
      const result = await diagnoseProblem(
        apiKey,
        description.trim(),
        photo?.base64,
        photo?.mediaType,
      )

      const diagnosis: Diagnosis = {
        id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
        timestamp: Date.now(),
        problemDescription: description.trim() || 'Photo analysis',
        photoBase64: photo?.base64,
        photoMediaType: photo?.mediaType,
        result,
      }

      onComplete(diagnosis)
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Unknown error occurred'
      if (message.includes('401') || message.includes('authentication')) {
        setError('Invalid API key. Please check your key in Settings.')
      } else if (message.includes('network') || message.includes('fetch')) {
        setError('Network error. Please check your connection and try again.')
      } else {
        setError(message || 'Failed to get diagnosis. Please try again.')
      }
    } finally {
      setLoading(false)
    }
  }

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
      }}>
        <button
          onClick={onBack}
          style={{
            background: 'none',
            color: 'var(--text-secondary)',
            fontSize: 24,
            padding: '4px 8px 4px 0',
            marginRight: 8,
          }}
        >
          ←
        </button>
        <h1 style={{ fontSize: 18, fontWeight: 700 }}>Describe the Problem</h1>
      </div>

      <div style={{ flex: 1, padding: '20px', display: 'flex', flexDirection: 'column', gap: 16 }}>

        {/* Photo upload */}
        <div>
          <label style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
            Photo (optional)
          </label>

          {photo ? (
            <div style={{ position: 'relative' }}>
              <img
                src={photo.preview}
                alt="Problem"
                style={{
                  width: '100%',
                  maxHeight: 220,
                  objectFit: 'cover',
                  borderRadius: 'var(--radius)',
                  border: '1px solid var(--border)',
                  display: 'block',
                }}
              />
              <button
                onClick={() => setPhoto(null)}
                style={{
                  position: 'absolute',
                  top: 8,
                  right: 8,
                  background: 'rgba(0,0,0,0.7)',
                  color: '#fff',
                  borderRadius: '50%',
                  width: 30,
                  height: 30,
                  fontSize: 16,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                ×
              </button>
            </div>
          ) : (
            <button
              onClick={() => fileRef.current?.click()}
              style={{
                width: '100%',
                padding: '24px',
                background: 'var(--bg-card)',
                border: '2px dashed var(--border-light)',
                borderRadius: 'var(--radius)',
                color: 'var(--text-muted)',
                fontSize: 14,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 6,
              }}
            >
              <span style={{ fontSize: 28 }}>📷</span>
              <span>Tap to add photo</span>
              <span style={{ fontSize: 11 }}>JPG, PNG, WEBP up to 5MB</span>
            </button>
          )}

          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            capture="environment"
            onChange={handlePhotoChange}
            style={{ display: 'none' }}
          />
        </div>

        {/* Text description */}
        <div style={{ flex: 1 }}>
          <label style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.06em' }}>
            Describe the Problem
          </label>
          <textarea
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="E.g. 'There's a brown water stain on my ceiling that's been getting bigger. The room above is a bathroom. No visible leak yet but it looks wet.'"
            rows={6}
            style={{
              width: '100%',
              padding: '14px',
              background: 'var(--bg-input)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius)',
              color: 'var(--text-primary)',
              fontSize: 15,
              lineHeight: 1.6,
              resize: 'none',
              transition: 'border-color var(--transition)',
            }}
            onFocus={e => e.currentTarget.style.borderColor = 'var(--orange)'}
            onBlur={e => e.currentTarget.style.borderColor = 'var(--border)'}
          />
        </div>

        {/* Suggestions */}
        <div>
          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginBottom: 8 }}>QUICK EXAMPLES</p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {[
              'Water stain on ceiling',
              'Outlet not working',
              'Door won\'t close',
              'Dripping faucet',
              'Cracks in drywall',
            ].map(s => (
              <button
                key={s}
                onClick={() => setDescription(s)}
                style={{
                  padding: '6px 10px',
                  background: 'var(--bg-card)',
                  border: '1px solid var(--border)',
                  borderRadius: 20,
                  color: 'var(--text-secondary)',
                  fontSize: 12,
                }}
              >
                {s}
              </button>
            ))}
          </div>
        </div>

        {error && (
          <div style={{
            padding: '12px 14px',
            background: 'var(--red-bg)',
            border: '1px solid rgba(239,68,68,0.3)',
            borderRadius: 'var(--radius-sm)',
            color: 'var(--red)',
            fontSize: 13,
          }}>
            {error}
          </div>
        )}

        <button
          onClick={handleSubmit}
          disabled={loading || (!description.trim() && !photo)}
          style={{
            width: '100%',
            padding: '16px',
            background: loading || (!description.trim() && !photo)
              ? 'var(--bg-card)'
              : 'linear-gradient(135deg, var(--orange) 0%, var(--orange-dark) 100%)',
            borderRadius: 'var(--radius)',
            color: loading || (!description.trim() && !photo) ? 'var(--text-muted)' : '#fff',
            fontSize: 16,
            fontWeight: 700,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 8,
            boxShadow: (!loading && (description.trim() || photo)) ? '0 4px 20px rgba(249,115,22,0.3)' : 'none',
            transition: 'all var(--transition)',
          }}
        >
          {loading ? (
            <>
              <span style={{
                width: 18,
                height: 18,
                border: '2px solid rgba(255,255,255,0.3)',
                borderTopColor: '#fff',
                borderRadius: '50%',
                animation: 'spin 0.8s linear infinite',
                display: 'inline-block',
              }} />
              Diagnosing...
            </>
          ) : (
            <>🔍 Diagnose Problem</>
          )}
        </button>
      </div>
    </div>
  )
}
