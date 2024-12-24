import React from 'react';
import { ChevronDown } from 'lucide-react';
import { Card } from '../ui/card';

const faqs = [
  {
    question: "How do I generate a review?",
    answer: "To generate a review, simply paste your patient data into the input field on the dashboard and click the arrow button. The AI will analyze the data and generate a comprehensive review."
  },
  {
    question: "What data do I need for manual entry?",
    answer: "For manual entry, you'll need basic patient information (name, DOB, gender) and clinical data including chief complaint, present illness, physical examination findings, and treatment plan."
  },
  {
    question: "How can I edit or download a report?",
    answer: "Once a report is generated, you can edit it using the edit button (pencil icon) in the review panel. To download, click the download icon to save the report as a text file."
  },
  {
    question: "Is my data secure?",
    answer: "Yes, all data is encrypted and stored securely. We comply with HIPAA regulations and use industry-standard security measures to protect your information."
  }
];

export function FAQ() {
  return (
    <div className="space-y-4">
      {faqs.map((faq, index) => (
        <Card key={index} className="p-6 bg-white">
          <details className="group">
            <summary className="flex justify-between items-center cursor-pointer list-none">
              <h3 className="text-lg font-medium text-gray-900">{faq.question}</h3>
              <ChevronDown className="w-5 h-5 text-gray-500 group-open:rotate-180 transition-transform" />
            </summary>
            <p className="mt-4 text-gray-600 leading-relaxed">
              {faq.answer}
            </p>
          </details>
        </Card>
      ))}
    </div>
  );
}