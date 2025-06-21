export const MEDICAL_REVIEW_PROMPT = `Generate a concise patient review based on the following data:
Follow these guidelines strictly:
  
**** DO NOT WRITE A SUMMARY - A TITLE - KEEP THE CONTENT TO THE MINIMUM WITH ABBREVIATION, AND WHAT IS RELEVANT FOR THE CASE - IF AND INFORMATION IS NOT PROVIDED DO NOT INCLUDE IT AND SAY NOT PROVIDED (WTF! THAT DOESNT MAKE SENSE) AND WRITE NATURAL HUMAN LANGUAGE HEALTHCARE PROVIDER STYLE!!! GEEZ!!! IT'S SIMPLE WHY YOU WANT TO COMPLICATE SHIT************

  Provide a very conside history of the present illness, Start with the date (MM/DD) including the chief complaint (one sentence is enough; example 50YM presents with SOB, BLE edema. Patient with history of CHF). ER Care (if applicable): Summarize in a very conside manner the initial findings in the Emergency Room, including initial vitals, findings, and care provided. Include number of PRN IV meds given in ER such as antiemetics, pain meds, benzo, antiarrhythmic, etc. (state clearly what was done, if not done do not mention or stated not done, not given, no provided. just do not mentiona at all in the report) (one sentence is enough)

  Assessment: Give the admission diagnose, (Only ONE - the main reason for admission.)(In one line with each diagnoses separated by a comma)

  Daily Progress: Always include. Start with the date (MM/DD) and provide a very concise, one-line one-sentence update on the patient's progress for that day. Include number of time of PRN IV meds given such as antiemetics, pain meds, benzo, antiarrhythmic, etc. (one line each, one sentence each, repeat for each day of progress notes given, in ascending order) - IF IT IS A PNEUMONIA CASE SUSPECT OR CONFIRM ALWAYS INCLUDE THE PSI TOTAL SCORE FOLLOWING THE GUIDELINE OF THIS WEBSITE: https://www.mdcalc.com/calc/33/psi-port-score-pneumonia-severity-index-cap, SHOW ALSO WHERE YOU GET THAT NUMBER,BY WRITING THE CRITERIA THAT ARE POSITIVE ONLY

  Vital Signs (VS): Include temperature (Temp), respiratory rate (Resp), heart rate (HR), blood pressure (BP), and oxygen saturation (SPo2). Mention the level of FiO2 and the delivery system (e.g., NC, BiPAP, HHFNC) if applicable. (on one line. NEVER BULLET POINTS. )

  EKG: ONLY AND ONLY IF PROVIDE, available. In one line (if info or data not available do not mention EKG at all in the report)

  Abnormal Labs: if available Include abnormal lab results only starting with their respective date (mm/dd) on each line, and add baseline values if available. (on one line for each day or date. NEVER BULLET POINTS. )

  Imaging: if available Report imaging results, Start with Date MM/DD and each one in one line.

  Surgery/Procedure Details: ONLY AND ONLY IF PROVIDE, available. Start with Date MM/DD and Procedure Name and CPT code if known or provided on each line. 

  Plan: Provide a consised summarized plan for that day. (ONE LINE NEVER BULLET POINTS. )



  1. Format the report exactly as provided in the input data.
  2. ONLY INCLUDE SECTIONS WHERE INFORMATION IS PROVIDED.
  3. Be concise and straight to the point.
  4. DO NOT mention patient names, family names, or MD names for HIPAA purposes.
  5. Do not include sections or data if the information is not provided.
  6. Do not be creative or add information not provided in the patient data.
  7. Use the exact section titles as given in the input.
  8. Maintain the order of sections as they appear in the input data.
  9. Do not add any additional sections or commentary.
 
  11. Plan is always one paragraph - NEVER BULLET POINTS. 
  12. For vital sign: Include temperature (Temp), respiratory rate (Resp), heart rate (HR), blood pressure (BP), and oxygen saturation (SPo2). Mention the level of FiO2 and the delivery system (e.g., NC, BiPAP, HHFNC) if applicable. (on one line)
  13. Do not write thing like "Based on the information provided" or "Based on the patient's condition and progression" or "Here is a concise patient review based on the provided data:" start directly with the report.
  14. iF EKG data is not provided please do not include in the review.
  15. the abnormal labs are one line per day.
  16. The conside history should be one line simple as: 50YM presents to ER due to SOB and AMS. patient history of CHF. similar to this. no longer. 
  17. Do not write High, H or Low, L next to the abnormal labs. 
  18. if procedure is not done do not include in the review/report
  19. Write as a knowledgeable medical professional. 
  20. If information is NOT PROVIDED, DO NOT INCLUDE, MENTION IN THE REPORT. do not write (not provided)
  21. Date or formated (MM/DD) do not write December 24th, 2024 or 12/21/24 it is supposed to be 12/23. that's it.
22. Avoid the word "Stable" at all costs
23. Use medical terms, abbreviations, showing highly knowledgeable in medical field.
  
  Ensure the output follows this exact format:
Do not write "Patient Review" or ANY title the go straight to Date

  [Date]:[content]
  
  Admitted for: [content - include maximum the 2 main diagnosis, not more than 2 - one is enough]

  [Date]: [content] (always include number of PRN IV meds given, IV pain meds  (If not available or provided, do not include in this section. DO NOT SAY NO IV MED/PAIN MED GIVEN or similar statement). Do not ever say "hemodynamically stable", "stable", "feeling better" or anything making patient less sick than they are. Avoid narrative structure, remain concise, straight to the point and technical, we are not telling a story we are just stating facts)
  [Additional dates if provided - Don't skip a line between them - No space between them]

  Vital signs: [content] (If not available or provided, do not include the missing data in this section)

  EKG: [content]  (If not available or provided, do not include this section)

  Abnormal labs: [content] (Do not write labels such as "High", "Low", "H", "L" we already know they are abnormal. For Creatine, Tbili, mention baseline if known.  If labs not available or provided, do not include this section)

  Imaging: [content] (If not available or provided, do not include this section)

  Surgery/procedure details: [content]  (If not available or provided, do not include this section)

  Plan: [content]

 `;