import Anthropic from '@anthropic-ai/sdk'
import type { DiagnosisResult } from './types'

const SYSTEM_PROMPT = `You are FixIt, an expert home repair diagnosis AI. When a user describes a home problem (with optional photo), you must respond with a JSON object exactly matching this schema:

{
  "whatIsWrong": "Plain English explanation of the problem (2-4 sentences)",
  "severity": "low" | "medium" | "high",
  "severityExplanation": "One sentence explaining why this severity level",
  "isDIY": true | false,
  "diySteps": ["Step 1...", "Step 2...", ...] (only if isDIY is true, 3-8 clear steps),
  "estimatedCost": "e.g. '$50–$150 for parts' or '$200–$800 contractor cost'",
  "contractorType": "e.g. 'Licensed plumber'" (only if isDIY is false),
  "contractorNotes": "What to tell the contractor, what to watch out for" (only if isDIY is false)
}

Severity guide:
- low (green): Cosmetic or minor issue, not urgent, no safety risk
- medium (yellow): Should fix within weeks, minor inconvenience or slow damage
- high (red): Safety hazard, structural risk, or active damage — fix immediately

Respond ONLY with the JSON object, no markdown, no explanation outside the JSON.`

export async function diagnoseProblem(
  apiKey: string,
  description: string,
  photoBase64?: string,
  photoMediaType?: string,
): Promise<DiagnosisResult> {
  const client = new Anthropic({
    apiKey,
    dangerouslyAllowBrowser: true,
  })

  const content: Anthropic.MessageParam['content'] = []

  if (photoBase64 && photoMediaType) {
    content.push({
      type: 'image',
      source: {
        type: 'base64',
        media_type: photoMediaType as 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp',
        data: photoBase64,
      },
    })
  }

  content.push({
    type: 'text',
    text: description || 'Please diagnose the home repair issue shown in this photo.',
  })

  const response = await client.messages.create({
    model: 'claude-sonnet-4-0',
    max_tokens: 1024,
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content }],
  })

  const textBlock = response.content.find(b => b.type === 'text')
  if (!textBlock || textBlock.type !== 'text') {
    throw new Error('No text response from Claude')
  }

  try {
    const parsed = JSON.parse(textBlock.text) as DiagnosisResult
    return parsed
  } catch {
    throw new Error('Failed to parse diagnosis response. Please try again.')
  }
}
