// FHIR Resource Types
export type FHIRPatient = {
  resourceType: 'Patient';
  id: string;
  meta: {
    lastUpdated: string;
  };
  identifier: Array<{
    system: string;
    value: string;
  }>;
  name: Array<{
    use: string;
    family: string;
    given: string[];
    prefix?: string[];
  }>;
  gender: 'male' | 'female' | 'other' | 'unknown';
  birthDate: string;
  address?: Array<{
    line: string[];
    city: string;
    state: string;
    postalCode: string;
    country: string;
  }>;
  telecom?: Array<{
    system: string;
    value: string;
    use?: string;
  }>;
};

// Mapped Patient Type (matches our database schema)
export type MappedPatient = {
  mrn: string;
  full_name: string;
  date_of_birth: string;
  gender: string;
  contact_info?: {
    address?: string;
    phone?: string;
    email?: string;
  };
};