# ChartExpert Theme Implementation Guide

## Quick Start

### 1. Theme Toggle
The theme toggle is already integrated. To add it to any page:
```jsx
import { ThemeToggle } from '../components/ui/theme-toggle';

// In your component
<ThemeToggle />
```

### 2. Using the New Components

#### Cards with Glassmorphism
```jsx
import { Card } from '../components/ui/card';

// Glass card (default)
<Card className="p-6">
  <h3 className="font-title text-xl mb-2">Card Title</h3>
  <p className="font-body text-muted-foreground">Card content...</p>
</Card>

// Subtle glass card
<Card variant="glass-subtle" size="lg" className="p-8">
  {/* Content */}
</Card>
```

#### Buttons
```jsx
import { Button } from '../components/ui/button';

// Primary button
<Button variant="primary" onClick={handleClick}>
  Save Changes
</Button>

// Loading button
<Button variant="secondary" isLoading>
  Processing...
</Button>

// Full width button
<Button variant="glass" className="w-full">
  Continue
</Button>
```

#### Inputs
```jsx
import { Input } from '../components/ui/input';

// Glass input (default)
<Input 
  type="email" 
  placeholder="Enter your email"
  value={email}
  onChange={(e) => setEmail(e.target.value)}
/>

// Default input
<Input variant="default" type="text" />
```

### 3. Applying Theme Colors

Use Tailwind classes with the new color names:
```jsx
// Text colors
<p className="text-onyx dark:text-french-gray">Main text</p>
<p className="text-picton-blue">Primary colored text</p>
<p className="text-muted-foreground">Muted text</p>

// Background colors
<div className="bg-lavender-web">Light background</div>
<div className="bg-picton-blue">Primary background</div>
<div className="bg-gradient-dark">Dark theme gradient</div>

// Gradients
<div className="gradient-primary">Primary gradient</div>
<div className="gradient-secondary">Secondary gradient</div>
```

### 4. Typography

Always use the appropriate font classes:
```jsx
// Headings (Comfortaa)
<h1 className="font-title text-4xl">Main Heading</h1>
<h2 className="font-title text-2xl">Subheading</h2>

// Body text (Questrial)
<p className="font-body">Regular paragraph text</p>
<span className="font-body text-sm">Small text</span>
```

### 5. Animations

Add smooth animations to elements:
```jsx
// Fade animations
<div className="animate-fade-in">Fades in</div>
<div className="animate-fade-in-up">Slides up while fading</div>
<div className="animate-fade-in-down">Slides down while fading</div>

// Hover effects
<Card className="hover:scale-105 transition-transform duration-300">
  Scales on hover
</Card>

// Custom transitions
<div className="transition-all duration-300 hover:shadow-lg">
  Smooth shadow transition
</div>
```

### 6. Dark Mode Support

Always consider both themes:
```jsx
// Text that adapts to theme
<p className="text-onyx dark:text-french-gray">
  Adaptive text color
</p>

// Background that adapts
<div className="bg-white dark:bg-oxford-blue/10">
  Adaptive background
</div>

// Conditional styling
<Card className="bg-white/80 dark:bg-white/5">
  Theme-aware card
</Card>
```

### 7. Common Patterns

#### Login/Auth Form
```jsx
<Card variant="glass" className="p-8 w-full max-w-md">
  <h2 className="font-title text-2xl mb-6 text-center">Welcome Back</h2>
  
  <form className="space-y-4">
    <div>
      <label className="block text-sm font-medium mb-2">Email</label>
      <Input type="email" placeholder="you@example.com" />
    </div>
    
    <div>
      <label className="block text-sm font-medium mb-2">Password</label>
      <Input type="password" placeholder="••••••••" />
    </div>
    
    <Button variant="primary" className="w-full">
      Sign In
    </Button>
  </form>
</Card>
```

#### Dashboard Card
```jsx
<Card variant="glass" size="md" className="p-6">
  <div className="flex items-center justify-between mb-4">
    <h3 className="font-title text-lg">Total Reports</h3>
    <span className="text-2xl font-bold text-picton-blue">247</span>
  </div>
  <p className="text-sm text-muted-foreground">
    +12% from last month
  </p>
</Card>
```

### 8. Responsive Design

Use responsive utilities:
```jsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {/* Cards automatically adjust to screen size */}
</div>

<h1 className="text-2xl md:text-3xl lg:text-4xl font-title">
  Responsive heading
</h1>
```

## Testing Your Implementation

1. **Theme Switching**: Toggle between light and dark themes
2. **Hover States**: Ensure all interactive elements have hover effects
3. **Responsiveness**: Test on different screen sizes
4. **Animations**: Check that animations are smooth and not jarring
5. **Accessibility**: Verify color contrast meets WCAG standards

## Need Help?

- View the Style Guide at `/style-guide` route
- Check `THEME_UPDATE.md` for complete documentation
- Reference existing components for examples