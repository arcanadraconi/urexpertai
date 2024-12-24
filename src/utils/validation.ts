export function validateEmail(email: string): string | null {
  if (!email) {
    return 'Email is required';
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return 'Invalid email format';
  }
  
  return null;
}

export function validatePassword(password: string): string | null {
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
  
  return null;
}

export function validateOrganizationName(name: string): string | null {
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

  return null;
}