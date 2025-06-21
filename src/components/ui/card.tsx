import { cn } from "../../utils/cn";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'glass' | 'glass-subtle';
  size?: 'sm' | 'md' | 'lg';
}

export function Card({ 
  className, 
  variant = 'glass',
  size = 'md',
  ...props 
}: CardProps) {
  const variants = {
    default: "bg-card border border-border",
    glass: "glass-card",
    'glass-subtle': "glass-card-subtle"
  };

  const sizes = {
    sm: "rounded-xl shadow-sm hover:shadow-md",
    md: "rounded-xl shadow-md hover:shadow-lg",
    lg: "rounded-2xl shadow-lg hover:shadow-xl"
  };

  return (
    <div
      className={cn(
        "text-card-foreground transition-all duration-300 animate-fade-in-up",
        variants[variant],
        sizes[size],
        className
      )}
      {...props}
    />
  );
}