import React from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { FAQ } from './FAQ';
import { Tutorials } from './Tutorials';
import { Documentation } from './Documentation';
import { ContactForm } from './ContactForm';

export function HelpLayout() {
  return (
    <div className="w-full max-w-6xl mx-auto p-6">
      <h1 className="text-3xl font-light text-[#1d7f84] mb-8">Help Center</h1>
      
      <Tabs defaultValue="faq" className="w-full">
        <TabsList className="mb-8">
          <TabsTrigger value="faq">FAQ</TabsTrigger>
          <TabsTrigger value="tutorials">Tutorials</TabsTrigger>
          <TabsTrigger value="documentation">Documentation</TabsTrigger>
          <TabsTrigger value="contact">Contact Us</TabsTrigger>
        </TabsList>

        <TabsContent value="faq">
          <FAQ />
        </TabsContent>

        <TabsContent value="tutorials">
          <Tutorials />
        </TabsContent>

        <TabsContent value="documentation">
          <Documentation />
        </TabsContent>

        <TabsContent value="contact">
          <ContactForm />
        </TabsContent>
      </Tabs>
    </div>
  );
}