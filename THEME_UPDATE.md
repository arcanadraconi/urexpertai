# ChartExpert Theme Update

## Overview
The ChartExpert application has been updated with a modern, clean, and minimal design system featuring:
- New color palette inspired by healthcare and trust
- Glassmorphism effects for a modern look
- Custom typography with Comfortaa and Questrial fonts
- Light and dark theme support
- Smooth animations and transitions

## Color Palette

### Primary Colors
- **White** (#FFFFFF) - Base color for cards and content
- **Lavender Web** (#DCE1EF) - Light theme background
- **French Gray** (#CFD0DD) - Dark theme text, muted elements
- **Onyx** (#3B3C48) - Light theme text

### Brand Colors
- **Picton Blue** (#17AADF) - Primary action color
- **Lapis Lazuli** (#225FAA) - Primary hover state
- **Amethyst** (#9B60BD) - Secondary/accent color
- **Russian Violet** (#382456) - Secondary hover state
- **Oxford Blue** (#05072F) - Darkest color, used sparingly

## Typography
- **Headings**: Comfortaa (300, 400, 600, 700)
- **Body Text**: Questrial (400)

## Component Updates

### Cards
```jsx
<Card variant="glass" size="md">
  {/* Content */}
</Card>
```
- Variants: `default`, `glass`, `glass-subtle`
- Sizes: `sm`, `md`, `lg`

### Buttons
```jsx
<Button variant="primary" size="md">
  Click me
</Button>
```
- Variants: `primary`, `secondary`, `glass`, `ghost`, `danger`
- Sizes: `sm`, `md`, `lg`
- States: `isLoading`, `disabled`

### Inputs
```jsx
<Input type="text" variant="glass" placeholder="Enter text..." />
```
- Variants: `default`, `glass`

## Theme Toggle
The application now supports light and dark themes with a smooth transition:
- Light theme: Lavender web background with dark text
- Dark theme: Gradient background (slate-950 → purple-950 → indigo-950) with light text

## CSS Classes

### Glassmorphism
- `.glass-card` - Standard glass effect
- `.glass-card-subtle` - Subtle glass effect
- `.input-glass` - Glass effect for inputs

### Gradients
- `.gradient-primary` - Picton Blue to Lapis Lazuli
- `.gradient-secondary` - Amethyst to Russian Violet
- `.bg-gradient-dark` - Dark theme background gradient

### Animations
- `.animate-fade-in` - Fade in animation
- `.animate-fade-in-up` - Fade in from bottom
- `.animate-fade-in-down` - Fade in from top

## Usage Examples

### Page Layout
```jsx
<div className="min-h-screen bg-lavender-web dark:bg-gradient-dark">
  <Card variant="glass" size="lg" className="p-8">
    <h1 className="text-3xl font-title mb-4">Page Title</h1>
    <p className="text-muted-foreground font-body">Content goes here...</p>
  </Card>
</div>
```

### Form Example
```jsx
<Card variant="glass" className="p-6">
  <h2 className="text-2xl font-title mb-4">Login</h2>
  <div className="space-y-4">
    <Input type="email" variant="glass" placeholder="Email" />
    <Input type="password" variant="glass" placeholder="Password" />
    <Button variant="primary" className="w-full">
      Sign In
    </Button>
  </div>
</Card>
```

## Best Practices
1. Use glass effects sparingly for important UI elements
2. Maintain consistent spacing using the predefined scale
3. Use appropriate color contrast for accessibility
4. Apply animations to enhance user experience, not distract
5. Test both light and dark themes for all new components

## Migration Notes
- Replace old color classes with new palette colors
- Update button classes to use the new Button component
- Apply glass effects to cards and modals
- Ensure all text uses either font-title or font-body
- Test theme switching functionality