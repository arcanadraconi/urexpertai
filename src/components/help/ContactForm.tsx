import React, { useState } from 'react';
import { Card } from '../ui/card';
import { Send } from 'lucide-react';

export function ContactForm() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: ''
  });
  const [sending, setSending] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSending(true);
    // TODO: Implement form submission
    setTimeout(() => setSending(false), 1000);
  };

  return (
    <Card className="p-8 bg-white max-w-2xl mx-auto">
      <h2 className="text-2xl font-medium text-gray-900 mb-6">Contact Support</h2>
      
      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Name
          </label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-[#1d7f84] focus:border-[#1d7f84]"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Email
          </label>
          <input
            type="email"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-[#1d7f84] focus:border-[#1d7f84]"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Subject
          </label>
          <input
            type="text"
            value={formData.subject}
            onChange={(e) => setFormData({ ...formData, subject: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-[#1d7f84] focus:border-[#1d7f84]"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Message
          </label>
          <textarea
            value={formData.message}
            onChange={(e) => setFormData({ ...formData, message: e.target.value })}
            rows={5}
            className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-[#1d7f84] focus:border-[#1d7f84]"
            required
          />
        </div>

        <button
          type="submit"
          disabled={sending}
          className="w-full flex items-center justify-center px-6 py-3 bg-[#1d7f84] text-white rounded-md hover:bg-[#1d7f84]/90 transition-colors disabled:opacity-50"
        >
          <Send className="w-4 h-4 mr-2" />
          {sending ? 'Sending...' : 'Send Message'}
        </button>
      </form>

      <div className="mt-8 pt-6 border-t border-gray-200">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Other Ways to Reach Us</h3>
        <div className="space-y-3 text-sm text-gray-600">
          <p>Email: support@urexpert.com</p>
          <p>Phone: (555) 123-4567</p>
          <p>Hours: Monday - Friday, 9:00 AM - 5:00 PM EST</p>
        </div>
      </div>
    </Card>
  );
}