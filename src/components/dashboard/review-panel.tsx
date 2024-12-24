import { Card } from "../ui/card";
import { FileText, Copy, ArrowDownToLine, Loader2 } from 'lucide-react';
import { useEffect, useState } from 'react';

interface ReviewPanelProps {
  review: string;
  isReady?: boolean;
}

export function ReviewPanel({ review, isReady }: ReviewPanelProps) {
  const [displayedText, setDisplayedText] = useState('');
  const [isEditing, setIsEditing] = useState(false);
  const [editableText, setEditableText] = useState('');
  const [copySuccess, setCopySuccess] = useState(false);

  useEffect(() => {
    if (!review) {
      setDisplayedText('');
      setEditableText('');
      return;
    }

    if (!isReady) {
      setDisplayedText('');
      setEditableText('');
      return;
    }

    let currentIndex = 0;
    const typingInterval = setInterval(() => {
      if (currentIndex < review.length) {
        setDisplayedText(prev => prev + review[currentIndex]);
        currentIndex++;
      } else {
        clearInterval(typingInterval);
        setEditableText(review);
      }
    }, 5);

    return () => clearInterval(typingInterval);
  }, [review, isReady]);

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleSave = () => {
    setDisplayedText(editableText);
    setIsEditing(false);
  };

  const handleCopy = async () => {
    if (displayedText) {
      try {
        await navigator.clipboard.writeText(displayedText);
        setCopySuccess(true);
        setTimeout(() => setCopySuccess(false), 2000);
      } catch (err) {
        console.error('Failed to copy text:', err);
      }
    }
  };

  const handleDownload = () => {
    if (displayedText) {
      const blob = new Blob([displayedText], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'medical-review.txt';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }
  };

  return (
    <div className="fixed right-0 top-0 h-full w-[800px] bg-[#5b828a]/10 p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-normal text-foreground">Generated Review</h2>
        <div className="flex gap-2">
          <button 
            onClick={isEditing ? handleSave : handleEdit}
            className="p-2 hover:bg-[#1d7f84]/10 rounded-md"
            title={isEditing ? "Save changes" : "Edit review"}
          >
            <FileText size={20} className="text-[#1d7f84]" />
          </button>
          <button 
            onClick={handleCopy}
            className="p-2 hover:bg-[#1d7f84]/10 rounded-md"
            title="Copy to clipboard"
          >
            <Copy size={20} className="text-[#1d7f84]" />
          </button>
          <button 
            onClick={handleDownload}
            className="p-2 hover:bg-[#1d7f84]/10 rounded-md"
            title="Download review"
          >
            <ArrowDownToLine size={20} className="text-[#1d7f84]" />
          </button>
        </div>
      </div>
      <div className="h-[calc(100vh-8rem)] overflow-hidden">
        <Card className="h-full bg-card text-card-foreground p-6 overflow-y-auto">
          {review && !isReady && (
            <div className="flex items-center justify-center h-full">
              <Loader2 className="w-8 h-8 animate-spin text-[#1d7f84]" />
            </div>
          )}
          {!review && (
            <div className="flex items-center justify-center h-full text-muted-foreground">
              Your review will appear here...
            </div>
          )}
          {displayedText && !isEditing && (
            <div className="space-y-4 text-sm whitespace-pre-wrap">
              {displayedText.split('\n').map((line, index) => {
                if (index === 0) {
                  return <h1 key={index} className="text-2xl font-bold mb-6">{line}</h1>;
                }
                return <p key={index}>{line}</p>;
              })}
            </div>
          )}
          {isEditing && (
            <textarea
              value={editableText}
              onChange={(e) => setEditableText(e.target.value)}
              className="w-full h-full p-4 text-sm border rounded-md focus:outline-none focus:ring-2 focus:ring-[#1d7f84] bg-background text-foreground"
              style={{ minHeight: '500px' }}
            />
          )}
        </Card>
      </div>
    </div>
  );
}