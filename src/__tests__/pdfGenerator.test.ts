import { describe, it, expect, vi } from 'vitest';
import { pdfGenerator } from '../lib/pdfGenerator';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';

vi.mock('html2canvas');
vi.mock('jspdf');

describe('pdfGenerator', () => {
  it('should generate PDF from report content', async () => {
    const mockReport = {
      id: '123',
      created_at: '2024-03-14T12:00:00Z',
      status: 'draft',
      content: {
        diagnosis: 'Test diagnosis',
        treatmentPlan: 'Test plan'
      }
    };

    const mockElement = document.createElement('div');
    const mockCanvas = {
      height: 1000,
      width: 800,
      toDataURL: vi.fn().mockReturnValue('data:image/png;base64,test')
    };

    (html2canvas as jest.Mock).mockResolvedValue(mockCanvas);
    (jsPDF as unknown as jest.Mock).mockImplementation(() => ({
      internal: {
        pageSize: {
          getWidth: () => 210
        }
      },
      text: vi.fn(),
      addImage: vi.fn(),
      output: vi.fn().mockReturnValue(new Blob())
    }));

    const result = await pdfGenerator.generateReportPDF(mockReport, mockElement);
    expect(result).toBeInstanceOf(Blob);
  });
});