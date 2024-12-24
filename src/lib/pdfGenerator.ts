import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import type { ProcessedReport } from '../types/report.types';

export const pdfGenerator = {
  async generateReportPDF(report: ProcessedReport, contentElement: HTMLElement): Promise<Blob> {
    const pdf = new jsPDF('p', 'mm', 'a4');
    const pageWidth = pdf.internal.pageSize.getWidth();
    const margin = 20;

    // Add header
    pdf.setFontSize(20);
    pdf.text('Medical Report', pageWidth / 2, margin, { align: 'center' });
    
    // Add report metadata
    pdf.setFontSize(12);
    pdf.text(`Report ID: ${report.id}`, margin, margin + 10);
    pdf.text(`Date: ${new Date(report.created_at).toLocaleDateString()}`, margin, margin + 15);
    pdf.text(`Status: ${report.status.toUpperCase()}`, margin, margin + 20);

    // Capture and add the report content
    const canvas = await html2canvas(contentElement, {
      scale: 2,
      logging: false,
      useCORS: true
    });

    const contentWidth = pageWidth - (margin * 2);
    const contentHeight = (canvas.height * contentWidth) / canvas.width;
    const contentImage = canvas.toDataURL('image/png');

    // Add the content image
    pdf.addImage(contentImage, 'PNG', margin, margin + 30, contentWidth, contentHeight);

    return pdf.output('blob');
  }
};