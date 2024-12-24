/**
 * Generates a formatted organization code in the format XXXX-XXXX-XXXX-XXXX
 */
export function generate_org_code(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const parts: string[] = [];
  
  for (let i = 0; i < 4; i++) {
    const part = Array.from(
      { length: 4 },
      () => chars[Math.floor(Math.random() * chars.length)]
    ).join('');
    parts.push(part);
  }
  
  return parts.join('-');
}