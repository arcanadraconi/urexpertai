export const getVerificationEmailTemplate = (verificationLink: string, verificationCode: string) => `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Your Email - URExpert</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.5;
            background-color: #f3f4f6;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        .card {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            padding: 32px;
        }
        .logo {
            display: block;
            margin: 0 auto 24px;
            height: 48px;
        }
        .heading {
            color: #111827;
            font-size: 24px;
            font-weight: 600;
            text-align: center;
            margin: 0 0 16px;
        }
        .text {
            color: #4b5563;
            font-size: 16px;
            text-align: center;
            margin: 0 0 24px;
        }
        .button {
            display: block;
            width: 100%;
            max-width: 240px;
            margin: 0 auto 24px;
            padding: 12px 24px;
            background-color: #2563eb;
            color: white;
            text-decoration: none;
            text-align: center;
            font-weight: 500;
            border-radius: 6px;
        }
        .code {
            display: block;
            width: fit-content;
            margin: 0 auto 24px;
            padding: 12px 24px;
            background-color: #f3f4f6;
            border-radius: 6px;
            font-family: monospace;
            font-size: 18px;
            letter-spacing: 2px;
        }
        .footer {
            color: #6b7280;
            font-size: 14px;
            text-align: center;
            margin-top: 24px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <img src="cid:logo" alt="URExpert Logo" class="logo">
            <h1 class="heading">Verify Your Email</h1>
            <p class="text">
                Thank you for signing up! Please verify your email address to complete your registration and access your account.
            </p>
            <a href="${verificationLink}" class="button">Verify Email</a>
            <p class="text">Or enter this verification code:</p>
            <div class="code">${verificationCode}</div>
            <p class="text">
                This verification code will expire in 24 hours. If you didn't create an account with URExpert, you can safely ignore this email.
            </p>
        </div>
        <div class="footer">
            <p>© ${new Date().getFullYear()} URExpert. All rights reserved.</p>
            <p>URExpert AI, Inc.</p>
            <p>Need help? Contact us at support@urexpert.ai</p>
        </div>
    </div>
</body>
</html>
`;