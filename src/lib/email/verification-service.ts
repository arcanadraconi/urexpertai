import { transporter } from './config';
import { getVerificationEmailTemplate } from './templates/verification';
import path from 'path';

export const verificationService = {
  async sendVerificationEmail(email: string, verificationLink: string) {
    try {
      const verificationCode = verificationLink.split('/').pop() || '';
      const html = getVerificationEmailTemplate(verificationLink, verificationCode);

      const text = `
        Verify Your Email - URExpert

        Thank you for signing up! Please verify your email address to complete your registration.

        Click the following link to verify your email:
        ${verificationLink}

        Or enter this verification code:
        ${verificationCode}

        This verification code will expire in 24 hours.

        If you didn't create an account with URExpert, you can safely ignore this email.

        © ${new Date().getFullYear()} URExpert. All rights reserved.
        URExpert AI, Inc.
      `;

      const mailOptions = {
        from: 'URExpert.ai <no-reply@urexpert.ai>',
        to: email,
        subject: 'Verify Your Email - URExpert',
        text,
        html,
        attachments: [{
          filename: 'logo.png',
          path: path.join(process.cwd(), 'public', 'urexpertlogo.png'),
          cid: 'logo'
        }]
      };

      await transporter.sendMail(mailOptions);
      return { success: true };
    } catch (error) {
      console.error('Failed to send verification email:', error);
      throw error;
    }
  }
};