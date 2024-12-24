import { readFileSync } from 'fs';
import { join } from 'path';

const templatesDir = join(__dirname);

export const emailTemplates = {
  verification: readFileSync(join(templatesDir, 'verification.html'), 'utf-8')
};