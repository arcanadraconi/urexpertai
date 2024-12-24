export const MEDICAL_REVIEW_PROMPT = `Generate a concise patient review based on the following data:
Follow these guidelines strictly:
  
  Generate a title for the review with patient age (use exact age from the chart, do not abbreviate or modify), gender, and the main admission diagnosis. ex. 79M NSTEMI. The age must be copied exactly as it appears in the patient data.

  Provide a one sentence very concise history of the present illness, Start with the date (MM/DD) including the chief complaint. Format: [Age][Gender] presents with [chief complaint]. Include relevant history if provided. (one sentence only)

  Assessment: Give the admission diagnoses (In one line with each diagnoses separated by a comma) 

  Daily Progress: Always include. Start with the date (MM/DD) and provide a very concise, one-line update on the patient's progress for that day. Include number of time of PRN IV meds given such as antiemetics, pain meds, benzo, antiarrhythmic, etc. (one line each, repeat for each day of progress notes given, in ascending order)

  Vital Signs (VS): Include temperature (Temp), respiratory rate (Resp), heart rate (HR), blood pressure (BP), and oxygen saturation (SPo2). Mention the level of FiO2 and the delivery system (e.g., NC, BiPAP, HHFNC) if applicable. (on one line. NEVER BULLET POINTS. )

  EKG: ONLY AND ONLY IF PROVIDE, available. In one line (if info or data not available do not mention EKG at all in the report)

  Abnormal Labs: if available Include abnormal lab results only starting with their respective date (mm/dd) on each line, and add baseline values if available. (on one line. NEVER BULLET POINTS. )

  Imaging: if available Report imaging results, Start with Date MM/DD and each one in one line.

  Surgery/Procedure Details: ONLY AND ONLY IF PROVIDE, available. Start with Date MM/DD and Procedure Name and CPT code if known or provided on each line. 

  Plan: Provide a consised summarized plan for that day. (ONE LINE NEVER BULLET POINTS. )

  Summary of hospital stay: Provide a detailed and comprehensive explanation of why the chosen status (IP, OSV, Outpatient, PA) is appropriate based on the patient's condition, symptoms, initial treatment and response, and progression and anticipation of treatment based on consultation, patient commorbidities and other aspect that may affect their prognosis. this part should detailed including past medical history and everything that is pertinent to the case that justify admission status. (a paragraph)

  Recommendation for status: Specify either Inpatient (IP), Observation (OSV), Outpatient, or Send to PA based on the clinical information provided.

  InterQual Subset: Indicate the most appropriate InterQual Subset relevant to the case.

  1. Format the report exactly as provided in the input data.
  2. ONLY INCLUDE SECTIONS WHERE INFORMATION IS PROVIDED.
  3. Be concise and straight to the point.
  4. DO NOT mention patient names, family names, or MD names for HIPAA purposes.
  5. Do not include sections or data if the information is not provided.
  6. Do not be creative or add information not provided in the patient data.
  7. Use the exact section titles as given in the input.
  8. Maintain the order of sections as they appear in the input data.
  9. Do not add any additional sections or commentary.
  10. Summary of status: Provide a brief explanation of why the chosen status (IP, OSV, Outpatient, PA) is appropriate based on the patient's condition and progression. (short paragraph)
  11. Plan is always one paragraph - NEVER BULLET POINTS. 
  12. For vital sign: Include temperature (Temp), respiratory rate (Resp), heart rate (HR), blood pressure (BP), and oxygen saturation (SPo2). Mention the level of FiO2 and the delivery system (e.g., NC, BiPAP, HHFNC) if applicable. (on one line)
  13. Do not write thing like "Based on the information provided" or "Based on the patient's condition and progression" or "Here is a concise patient review based on the provided data:" start directly with the report.
  14. iF EKG data is not provided please do not include in the review.
  15. the abnormal labs are one line per day.
  16. Present the history naturally using the patient's actual symptoms and complaints.
  17. DO NOT put high and low nor H OR L in the abnormal labs values.
  18. WRITE LIKE A MEDICAL PROFESSIONAL
 
  
  Ensure the output follows this exact format:

  [Title]

  [Date]:[content]
  
  Admitted for: [content]

  [Date]: [content]
  [Additional dates if provided]

  Vital signs: [content]

  EKG: [content]

  Abnormal labs: [content]

  Imaging: [content]

  Surgery/procedure details: [content]

  Plan: [content]

  Summary of status: [content]

  Recommendation for status: [MUST BE ONLY ONE OF: Inpatient, Observation, Outpatient, or Send to PA for secondary review]

  InterQual subset: [Specify the exact InterQual subset name, do not use generic terms like 'Inpatient']"`;