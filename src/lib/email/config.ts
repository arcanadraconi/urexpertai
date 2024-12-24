import { createTransport } from 'nodemailer';

export const emailConfig = {
  host: "sandbox.smtp.mailtrap.io",
  port: 2525,
  auth: {
    user: "24706683bd70a8",
    pass: "669928abca4027"
  }
};

export const transporter = createTransport(emailConfig);