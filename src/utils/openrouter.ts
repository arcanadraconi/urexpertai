import { supabase } from '../lib/supabase';
import { MEDICAL_REVIEW_PROMPT } from './prompts/medical-review';

const OPENROUTER_API_KEY = import.meta.env.VITE_OPENROUTER_API_KEY;
const OPENROUTER_MODEL = 'anthropic/claude-3-haiku';

export class OpenRouterService {
  static async generateReview(input: string) {
    if (!OPENROUTER_API_KEY) {
      throw new Error('OpenRouter API key is not configured');
    }

    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user) {
      throw new Error('Please sign in to generate reviews');
    }

    try {
      const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': window.location.origin,
          'X-Title': 'URExpert'
        },
        body: JSON.stringify({
          model: OPENROUTER_MODEL,
          messages: [
            {
              role: 'system',
              content: MEDICAL_REVIEW_PROMPT
            },
            {
              role: 'user',
              content: input
            }
          ],
          temperature: 0.1,
          max_tokens: 2000,
          top_p: 0.1,
          frequency_penalty: 0.1,
          presence_penalty: 0.1
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error?.message || 'Failed to generate review');
      }

      const data = await response.json();
      return {
        text: data.choices[0].message.content,
        model: data.model
      };
    } catch (error) {
      console.error('OpenRouter API error:', error);
      throw error instanceof Error ? error : new Error('Failed to generate review');
    }
  }
}