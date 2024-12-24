import { Card } from "../ui/card";
import { Input } from "../ui/input";
import { Logo } from "../ui/logo";
import { ArrowRight, AlertCircle } from 'lucide-react';
import { useState } from 'react';
import { OpenRouterService } from '../../utils/openrouter';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';

interface ChatInterfaceProps {
  onReviewGenerated: (text: string, isReady?: boolean) => void;
}

export function ChatInterface({ onReviewGenerated }: ChatInterfaceProps) {
  const navigate = useNavigate();
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    setIsLoading(true);
    setError(null);
    onReviewGenerated(''); // Clear previous review

    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        navigate('/');
        return;
      }

      const response = await OpenRouterService.generateReview(input);
      onReviewGenerated(response.text, true);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to generate review';
      setError(message);
      onReviewGenerated(''); // Clear on error
      
      if (message.includes('sign in')) {
        navigate('/');
      }
    } finally {
      setIsLoading(false);
      setInput('');
    }
  };

  return (
    <div className="flex-1 flex items-center justify-center">
      <main className="container max-w-6xl mx-auto px-4">
        <div className="flex flex-col items-center justify-center h-screen">
          <Logo />
          <h1 className="mt-12 text-3xl font-light text-[#1d7f84] mx-auto">How can I help you today?</h1>
          <div className="mt-8 w-full max-w-2xl">
            <form onSubmit={handleSubmit}>
              <Card className="bg-[#5b828a]/10 border-0 mx-auto">
                <div className="relative">
                  <Input 
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    className="bg-transparent border-0 h-14 pl-4 pr-12 text-foreground placeholder:text-foreground/50" 
                    placeholder="Paste patient data here..."
                    disabled={isLoading}
                  />
                  <button 
                    type="submit"
                    disabled={isLoading || !input.trim()}
                    className="absolute right-3 top-1/2 -translate-y-1/2 w-8 h-8 flex items-center justify-center text-[#1d7f84] hover:text-[#489fa0] transition-colors disabled:opacity-50"
                  >
                    <ArrowRight size={20} />
                  </button>
                </div>
              </Card>
            </form>
            {error && (
              <div className="mt-4 p-4 bg-red-50 text-red-600 rounded-lg flex items-center gap-2">
                <AlertCircle className="w-5 h-5" />
                <span>{error}</span>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}