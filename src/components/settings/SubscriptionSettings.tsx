import React from 'react';
import { Card } from '../ui/card';
import { Check, AlertCircle } from 'lucide-react';

export function SubscriptionSettings() {
  const currentPlan = 'Basic';
  const expiryDate = '2024-12-31';

  const plans = [
    {
      name: 'Basic',
      price: 49,
      features: ['Basic report generation', 'Email support']
    },
    {
      name: 'Professional',
      price: 99,
      features: ['Basic report generation', 'Email support', 'Priority support']
    },
    {
      name: 'Enterprise',
      price: 199,
      features: ['Basic report generation', 'Email support', 'Priority support', 'Custom integrations']
    }
  ];

  return (
    <div className="space-y-6">
      {/* Current Plan Card */}
      <Card className="p-6 bg-white">
        <h2 className="text-xl font-medium text-gray-900 mb-4">Current Plan</h2>
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-2xl font-semibold text-[#1d7f84]">{currentPlan}</p>
            <p className="text-sm text-gray-600">Valid until {new Date(expiryDate).toLocaleDateString()}</p>
          </div>
          <button className="px-4 py-2 bg-[#1d7f84] text-white rounded-md hover:bg-[#1d7f84]/90 transition-colors">
            Upgrade Plan
          </button>
        </div>
      </Card>

      {/* Plan Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => (
          <Card key={plan.name} className={`p-6 bg-white ${plan.name === currentPlan ? 'ring-2 ring-[#1d7f84]' : ''}`}>
            <h3 className="text-lg font-medium text-gray-900 mb-2">{plan.name}</h3>
            <p className="text-3xl font-bold text-gray-900 mb-4">
              ${plan.price}
              <span className="text-sm font-normal text-gray-600">/month</span>
            </p>
            <ul className="space-y-3 mb-6">
              {plan.features.map((feature, index) => (
                <li key={index} className="flex items-center text-sm text-gray-700">
                  <Check className="w-4 h-4 text-green-500 mr-2" />
                  {feature}
                </li>
              ))}
            </ul>
            {plan.name === currentPlan ? (
              <button className="w-full px-4 py-2 bg-gray-100 text-gray-600 rounded-md" disabled>
                Current Plan
              </button>
            ) : (
              <button className="w-full px-4 py-2 bg-[#1d7f84] text-white rounded-md hover:bg-[#1d7f84]/90 transition-colors">
                Switch to {plan.name}
              </button>
            )}
          </Card>
        ))}
      </div>

      {/* Cancel Subscription Card */}
      <Card className="p-6 bg-white border-red-200">
        <div className="flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 text-red-500 mt-0.5" />
          <div>
            <h3 className="text-lg font-medium text-gray-900">Cancel Subscription</h3>
            <p className="text-sm text-gray-600 mt-1">
              Canceling your subscription will disable access to premium features at the end of your billing period.
            </p>
            <button className="mt-4 px-4 py-2 border border-red-500 text-red-500 rounded-md hover:bg-red-50 transition-colors">
              Cancel Subscription
            </button>
          </div>
        </div>
      </Card>
    </div>
  );
}