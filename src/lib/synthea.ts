import { FHIRPatient, MappedPatient } from '../types/fhir.types';
import { supabase } from './supabase';

export function mapFHIRToPatient(fhirPatient: FHIRPatient): MappedPatient {
  const name = fhirPatient.name[0];
  const fullName = [
    ...(name.prefix || []),
    ...(name.given || []),
    name.family
  ].join(' ');

  const mrn = fhirPatient.identifier.find(
    id => id.system === 'https://synthea.mitre.org/identifier/mrn'
  )?.value || fhirPatient.id;

  const contact_info: MappedPatient['contact_info'] = {};
  
  if (fhirPatient.address?.[0]) {
    const addr = fhirPatient.address[0];
    contact_info.address = [
      ...(addr.line || []),
      addr.city,
      addr.state,
      addr.postalCode,
      addr.country
    ].join(', ');
  }

  if (fhirPatient.telecom?.[0]) {
    const phone = fhirPatient.telecom.find(t => t.system === 'phone');
    const email = fhirPatient.telecom.find(t => t.system === 'email');
    if (phone) contact_info.phone = phone.value;
    if (email) contact_info.email = email.value;
  }

  return {
    mrn,
    full_name: fullName,
    date_of_birth: fhirPatient.birthDate,
    gender: fhirPatient.gender,
    contact_info: Object.keys(contact_info).length > 0 ? contact_info : undefined
  };
}

export async function importSyntheaPatients(patients: FHIRPatient[]) {
  const mappedPatients = patients.map(mapFHIRToPatient);
  
  // Insert patients in batches of 100
  const batchSize = 100;
  for (let i = 0; i < mappedPatients.length; i += batchSize) {
    const batch = mappedPatients.slice(i, i + batchSize);
    
    const { error } = await supabase
      .from('patients')
      .upsert(
        batch,
        { 
          onConflict: 'mrn',
          ignoreDuplicates: false 
        }
      );

    if (error) {
      console.error(`Error inserting batch ${i / batchSize + 1}:`, error);
      throw error;
    }
  }

  return mappedPatients.length;
}