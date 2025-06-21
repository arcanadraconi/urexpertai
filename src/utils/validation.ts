export function validateEmail(email: string): string | undefined {
  if (!email) {
    return 'Email is required';
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return 'Invalid email format';
  }
  
  return undefined;
}

export function validateOrganizationCode(code: string): string | undefined {
  if (!code) {
    return 'Organization code is required';
  }

  // Check for exact format: XXXX-XXXX-XXXX-XXXX
  const codeRegex = /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
  if (!codeRegex.test(code)) {
    return 'Invalid organization code format. Must be in XXXX-XXXX-XXXX-XXXX format';
  }

  return undefined;
}

export function validatePassword(password: string): string | undefined {
  if (!password) {
    return 'Password is required';
  }
  
  if (password.length < 8) {
    return 'Password must be at least 8 characters';
  }
  
  // Check for at least one number and one letter
  if (!/\d/.test(password) || !/[a-zA-Z]/.test(password)) {
    return 'Password must contain at least one letter and one number';
  }
  
  return undefined;
}

export function validateOrganizationName(name: string): string | undefined {
  if (!name) {
    return 'Organization name is required';
  }

  if (name.length < 2) {
    return 'Organization name must be at least 2 characters';
  }

  if (name.length > 100) {
    return 'Organization name must be less than 100 characters';
  }

  // Check for valid characters
  if (!/^[a-zA-Z0-9\s\-_.]+$/.test(name)) {
    return 'Organization name can only contain letters, numbers, spaces, hyphens, underscores, and periods';
  }

  return undefined;
}
