import React from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { SubscriptionSettings } from './SubscriptionSettings';
import { BillingHistory } from './BillingHistory';
import { NotificationSettings } from './NotificationSettings';
import { PreferencesSettings } from './PreferencesSettings';

export function SettingsLayout() {
  return (
    <div className="w-full max-w-6xl mx-auto p-6">
      <h1 className="text-3xl font-light text-[#1d7f84] mb-8">Settings</h1>
      
      <Tabs defaultValue="subscription" className="w-full">
        <TabsList className="mb-8">
          <TabsTrigger value="subscription">Subscription</TabsTrigger>
          <TabsTrigger value="billing">Billing</TabsTrigger>
          <TabsTrigger value="notifications">Notifications</TabsTrigger>
          <TabsTrigger value="preferences">Preferences</TabsTrigger>
        </TabsList>

        <TabsContent value="subscription">
          <SubscriptionSettings />
        </TabsContent>

        <TabsContent value="billing">
          <BillingHistory />
        </TabsContent>

        <TabsContent value="notifications">
          <NotificationSettings />
        </TabsContent>

        <TabsContent value="preferences">
          <PreferencesSettings />
        </TabsContent>
      </Tabs>
    </div>
  );
}