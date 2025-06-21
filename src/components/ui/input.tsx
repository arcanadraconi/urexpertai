import { cn } from "../../utils/cn"

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  variant?: 'default' | 'glass';
}

export function Input({ 
  className, 
  type,
  variant = 'glass',
  ...props 
}: InputProps) {
  const variants = {
    default: "border border-input bg-background",
    glass: "input-glass"
  };

  return (
    <input
      type={type}
      className={cn(
        "flex h-11 w-full rounded-xl px-4 py-2.5 text-sm font-body",
        "placeholder:text-muted-foreground",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-picton-blue focus-visible:ring-offset-2",
        "disabled:cursor-not-allowed disabled:opacity-50",
        "transition-all duration-200",
        "file:border-0 file:bg-transparent file:text-sm file:font-medium",
        variants[variant],
        className
      )}
      {...props}
    />
  )
}