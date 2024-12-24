import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { ThemeProvider } from './providers/theme-provider';
import { AuthProvider } from './contexts/AuthContext';
import { AppRoutes } from './routes/AppRoutes';
import { LoadingSpinner } from './components/common/LoadingSpinner';
import './styles/globals.css';

const App: React.FC = () => {
  return (
    <ThemeProvider defaultTheme="light" storageKey="urexpert-theme">
      <AuthProvider>
        <Router>
          <div className="min-h-screen bg-background text-foreground">
            <React.Suspense fallback={<LoadingSpinner />}>
              <AppRoutes />
            </React.Suspense>
          </div>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
};

export default App;