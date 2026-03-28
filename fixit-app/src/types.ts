export type SeverityLevel = 'low' | 'medium' | 'high'

export interface Diagnosis {
  id: string
  timestamp: number
  problemDescription: string
  photoBase64?: string
  photoMediaType?: string
  result: DiagnosisResult
}

export interface DiagnosisResult {
  whatIsWrong: string
  severity: SeverityLevel
  severityExplanation: string
  isDIY: boolean
  diySteps?: string[]
  estimatedCost: string
  contractorType?: string
  contractorNotes?: string
}

export type Screen = 'home' | 'input' | 'results' | 'history' | 'settings'
