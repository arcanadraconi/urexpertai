import nodemailer from 'nodemailer';
import { readFileSync } from 'fs';
import { join } from 'path';

const transporter = nodemailer.createTransport({
  host: "sandbox.smtp.mailtrap.io",
  port: 2525,
  auth: {
    user: "24706683bd70a8",
    pass: "669928abca4027"
  }
});

// Read template once at startup
const templatePath = join(process.cwd(), 'src', 'lib', 'email', 'templates', 'verification.html');
const template = readFileSync(templatePath, 'utf-8');

export const emailService = {
  async sendVerificationEmail(email: string, verificationLink: string) {
    const verificationCode = verificationLink.split('/').pop() || '';
    
    // Customize template
    let html = template;
    html = html.replace('{verification_link}', verificationLink);
    html = html.replace('{verification_code}', verificationCode);

    // Plain text version
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
        path: join(process.cwd(), 'public', 'urexpertlogo.png'),
        cid: 'logo'
      }]
    };

    try {
      await transporter.sendMail(mailOptions);
      return { success: true };
    } catch (error) {
      console.error('Failed to send verification email:', error);
      throw error;
    }
  }
};