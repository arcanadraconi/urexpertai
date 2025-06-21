import React from 'react';
import { Card } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { ThemeToggle } from '../ui/theme-toggle';

export function StyleGuide() {
  const colors = [
    { name: 'White', class: 'bg-white', hex: '#FFFFFF' },
    { name: 'Lavender Web', class: 'bg-lavender-web', hex: '#DCE1EF' },
    { name: 'French Gray', class: 'bg-french-gray', hex: '#CFD0DD' },
    { name: 'Onyx', class: 'bg-onyx', hex: '#3B3C48' },
    { name: 'Picton Blue', class: 'bg-picton-blue', hex: '#17AADF' },
    { name: 'Lapis Lazuli', class: 'bg-lapis-lazuli', hex: '#225FAA' },
    { name: 'Amethyst', class: 'bg-amethyst', hex: '#9B60BD' },
    { name: 'Russian Violet', class: 'bg-russian-violet', hex: '#382456' },
    { name: 'Oxford Blue', class: 'bg-oxford-blue', hex: '#05072F' }
  ];

  return (
    <div className="min-h-screen p-8 custom-scrollbar">
      <div className="max-w-7xl mx-auto space-y-12">
        {/* Header */}
        <div className="flex items-center justify-between animate-fade-in-down">
          <div>
            <h1 className="text-4xl font-title mb-2">ChartExpert Style Guide</h1>
            <p className="text-muted-foreground font-body">Modern healthcare application design system</p>
          </div>
          <ThemeToggle />
        </div>

        {/* Colors */}
        <Card size="lg" className="p-8">
          <h2 className="text-2xl font-title mb-6">Color Palette</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {colors.map((color) => (
              <div key={color.name} className="text-center">
                <div className={`${color.class} h-24 rounded-xl mb-3 shadow-md transition-transform hover:scale-105`}></div>
                <p className="font-title text-sm font-medium">{color.name}</p>
                <p className="text-xs text-muted-foreground font-body">{color.hex}</p>
              </div>
            ))}
          </div>
        </Card>

        {/* Typography */}
        <Card size="lg" className="p-8">
          <h2 className="text-2xl font-title mb-6">Typography</h2>
          <div className="space-y-6">
            <div>
              <h1 className="text-4xl font-title">Heading 1 - Comfortaa</h1>
              <h2 className="text-3xl font-title mt-2">Heading 2 - Comfortaa</h2>
              <h3 className="text-2xl font-title mt-2">Heading 3 - Comfortaa</h3>
              <h4 className="text-xl font-title mt-2">Heading 4 - Comfortaa</h4>
            </div>
            <div className="border-t pt-6">
              <p className="font-body text-lg">Body Large - Questrial</p>
              <p className="font-body">Body Regular - Questrial</p>
              <p className="font-body text-sm">Body Small - Questrial</p>
              <p className="font-body text-xs">Body Extra Small - Questrial</p>
            </div>
          </div>
        </Card>

        {/* Buttons */}
        <Card size="lg" className="p-8">
          <h2 className="text-2xl font-title mb-6">Buttons</h2>
          <div className="space-y-6">
            <div className="flex flex-wrap gap-4">
              <Button variant="primary">Primary Button</Button>
              <Button variant="secondary">Secondary Button</Button>
              <Button variant="glass">Glass Button</Button>
              <Button variant="ghost">Ghost Button</Button>
              <Button variant="danger">Danger Button</Button>
            </div>
            
            <div className="border-t pt-6">
              <h3 className="text-lg font-title mb-4">Button Sizes</h3>
              <div className="flex flex-wrap items-center gap-4">
                <Button size="sm">Small</Button>
                <Button size="md">Medium</Button>
                <Button size="lg">Large</Button>
              </div>
            </div>
            
            <div className="border-t pt-6">
              <h3 className="text-lg font-title mb-4">Button States</h3>
              <div className="flex flex-wrap gap-4">
                <Button disabled>Disabled</Button>
                <Button isLoading>Loading</Button>
              </div>
            </div>
          </div>
        </Card>

        {/* Cards */}
        <div>
          <h2 className="text-2xl font-title mb-6">Cards</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card variant="glass" size="sm" className="p-6">
              <h3 className="font-title text-lg mb-2">Small Glass Card</h3>
              <p className="text-sm text-muted-foreground">This is a small card with glass morphism effect and subtle shadow.</p>
            </Card>
            
            <Card variant="glass" size="md" className="p-6">
              <h3 className="font-title text-lg mb-2">Medium Glass Card</h3>
              <p className="text-sm text-muted-foreground">This is a medium card with standard shadow and hover effects.</p>
            </Card>
            
            <Card variant="glass-subtle" size="lg" className="p-6">
              <h3 className="font-title text-lg mb-2">Large Subtle Card</h3>
              <p className="text-sm text-muted-foreground">This is a large card with subtle glass effect and larger shadow.</p>
            </Card>
          </div>
        </div>

        {/* Forms */}
        <Card size="lg" className="p-8">
          <h2 className="text-2xl font-title mb-6">Form Elements</h2>
          <div className="space-y-6 max-w-md">
            <div>
              <label className="block text-sm font-medium mb-2">Glass Input</label>
              <Input type="text" placeholder="Enter text here..." variant="glass" />
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Default Input</label>
              <Input type="email" placeholder="email@example.com" variant="default" />
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Disabled Input</label>
              <Input type="text" placeholder="Disabled input" disabled />
            </div>
          </div>
        </Card>

        {/* Animations */}
        <Card size="lg" className="p-8">
          <h2 className="text-2xl font-title mb-6">Animations</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="animate-fade-in glass-card p-6 text-center">
              <h3 className="font-title mb-2">Fade In</h3>
              <p className="text-sm text-muted-foreground">.animate-fade-in</p>
            </div>
            
            <div className="animate-fade-in-up glass-card p-6 text-center">
              <h3 className="font-title mb-2">Fade In Up</h3>
              <p className="text-sm text-muted-foreground">.animate-fade-in-up</p>
            </div>
            
            <div className="animate-fade-in-down glass-card p-6 text-center">
              <h3 className="font-title mb-2">Fade In Down</h3>
              <p className="text-sm text-muted-foreground">.animate-fade-in-down</p>
            </div>
          </div>
        </Card>

        {/* Gradients */}
        <Card size="lg" className="p-8">
          <h2 className="text-2xl font-title mb-6">Gradients</h2>
          <div className="space-y-4">
            <div className="h-24 gradient-primary rounded-xl flex items-center justify-center text-white font-title">
              Primary Gradient
            </div>
            <div className="h-24 gradient-secondary rounded-xl flex items-center justify-center text-white font-title">
              Secondary Gradient
            </div>
            <div className="h-24 bg-gradient-dark rounded-xl flex items-center justify-center text-white font-title">
              Dark Theme Gradient
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}