import { Settings, HelpCircle, Moon, Sun, LogOut, ClipboardPlus, BarChart, CircleUserRound } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useTheme } from '../../providers/theme-provider';

type View = 'dashboard' | 'profile' | 'reports' | 'metrics' | 'help' | 'settings';

interface SidebarProps {
  onViewChange: (view: View) => void;
  currentView: View;
}

export function Sidebar({ onViewChange, currentView }: SidebarProps) {
  const navigate = useNavigate();
  const { setIsAuthenticated } = useAuth();
  const { theme, setTheme } = useTheme();

  const handleLogout = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      
      setIsAuthenticated(false);
      navigate('/', { replace: true });
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark');
  };

  return (
    <div className="fixed left-0 top-0 h-full w-16 flex flex-col bg-[#001426] py-4">
      <div className="flex-1 flex flex-col gap-4 mt-16">
        <SidebarIcon 
          icon={<CircleUserRound size={25} />} 
          label="My Profile" 
          active={currentView === 'profile'}
          onClick={() => onViewChange('profile')} 
        />
        <SidebarIcon 
          icon={<ClipboardPlus size={25} />} 
          label="Generate Report" 
          active={currentView === 'dashboard'}
          onClick={() => onViewChange('dashboard')} 
        />
        <SidebarIcon 
          icon={<BarChart size={25} />} 
          label="Metrics" 
          active={currentView === 'metrics'}
          onClick={() => onViewChange('metrics')} 
        />
        <SidebarIcon 
          icon={<HelpCircle size={25} />} 
          label="Help" 
          active={currentView === 'help'}
          onClick={() => onViewChange('help')} 
        />
        <SidebarIcon 
          icon={<Settings size={25} />} 
          label="Settings" 
          active={currentView === 'settings'}
          onClick={() => onViewChange('settings')} 
        />
      </div>
      <div className="flex flex-col gap-4 mb-4">
        <SidebarIcon 
          icon={theme === 'dark' ? <Sun size={25} /> : <Moon size={25} />} 
          label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
          onClick={toggleTheme}
        />
        <SidebarIcon 
          icon={<LogOut size={25} />} 
          label="Logout" 
          onClick={handleLogout} 
        />
      </div>
    </div>
  );
}

interface SidebarIconProps {
  icon: React.ReactNode;
  label: string;
  onClick?: () => void;
  active?: boolean;
}

function SidebarIcon({ icon, label, onClick, active }: SidebarIconProps) {
  return (
    <button 
      onClick={onClick}
      className={`w-10 h-10 mx-auto flex items-center justify-center relative group transition-colors
        ${active ? 'text-white' : 'text-white/70 hover:text-white'}`}
    >
      {icon}
      <span className="absolute left-full ml-2 px-2 py-1 bg-[#001426] text-white text-sm rounded opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap">
        {label}
      </span>
    </button>
  );
}