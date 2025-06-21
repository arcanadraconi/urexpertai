import { useState } from 'react';
import { Sidebar } from "./sidebar";
import { ProfileLayout } from "../profile/ProfileLayout";
import { ChatInterface } from "./chat-interface";
import { ReviewPanel } from "./review-panel";
import { MetricsLayout } from "../metrics/MetricsLayout";
import { HelpLayout } from "../help/HelpLayout";
import { SettingsLayout } from "../settings/SettingsLayout";

type View = 'dashboard' | 'profile' | 'reports' | 'metrics' | 'help' | 'settings';

export default function Dashboard() {
  const [currentView, setCurrentView] = useState<View>('dashboard');
  const [review, setReview] = useState<string>('');
  const [isReviewReady, setIsReviewReady] = useState(false);
  const [isSaved, setIsSaved] = useState(false);

  const handleReviewGenerated = (text: string, isReady?: boolean, saved?: boolean) => {
    setReview(text);
    setIsReviewReady(!!isReady);
    setIsSaved(!!saved);
  };

  const renderView = () => {
    switch (currentView) {
      case 'profile':
        return <ProfileLayout />;
      case 'metrics':
        return <MetricsLayout />;
      case 'help':
        return <HelpLayout />;
      case 'settings':
        return <SettingsLayout />;
      case 'dashboard':
      default:
        return (
          <div className="flex">
            <div className="flex-1">
              <ChatInterface onReviewGenerated={handleReviewGenerated} />
            </div>
            <aside className="w-[800px]">
              <ReviewPanel review={review} isReady={isReviewReady} isSaved={isSaved} />
            </aside>
          </div>
        );
    }
  };

  return (
    <div className="flex min-h-screen bg-background text-foreground">
      <aside className="w-16 bg-[#001426] text-white">
        <Sidebar onViewChange={setCurrentView} currentView={currentView} />
      </aside>
      <main className="flex-1">
        {renderView()}
      </main>
    </div>
  );
}