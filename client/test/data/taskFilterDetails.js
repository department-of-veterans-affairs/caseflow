export const taskFilterDetails = {
  in_progress: {
    '["BoardGrantEffectuationTask", "Appeal"]': 6,
    '["DecisionReviewTask", "HigherLevelReview"]': 330,
    '["DecisionReviewTask", "SupplementalClaim"]': 20,
    '["VeteranRecordRequest", "Appeal"]': 54
  },
  completed: {
    '["DecisionReviewTask", "HigherLevelReview"]': 12,
    '["DecisionReviewTask", "SupplementalClaim"]': 15,
    '["VeteranRecordRequest", "Appeal"]': 3
  },
  incomplete: {},
  in_progress_issue_types: {
    CHAMPVA: 12,
    'Caregiver | Tier Level': 20,
    Other: 24,
    'Eligibility for Dental Treatment': 16,
    'Spina Bifida Treatment (Non-Compensation)': 10,
    'Continuing Eligibility/Income Verification Match (IVM)': 12,
    'Prosthetics | Other (not clothing allowance)': 13,
    'Medical and Dental Care Reimbursement': 6,
    'Caregiver | Revocation/Discharge': 25,
    'Initial Eligibility and Enrollment in VHA Healthcare': 23,
    'Foreign Medical Program': 13,
    'Beneficiary Travel': 8,
    'Clothing Allowance': 10,
    'Caregiver | Eligibility': 11,
    'Caregiver | Other': 14,
    'Camp Lejune Family Member': 19
  },
  completed_issue_types: {
    'Beneficiary Travel': 17,
    'Clothing Allowance': 12,
    CHAMPVA: 15,
    'Continuing Eligibility/Income Verification Match (IVM)': 11,
    'Prosthetics | Other (not clothing allowance)': 9,
    'Medical and Dental Care Reimbursement': 9,
    'Eligibility for Dental Treatment': 12,
    'Caregiver | Revocation/Discharge': 6,
    'Caregiver | Tier Level': 8,
    Other: 14,
    'Caregiver | Eligibility': 8,
    'Spina Bifida Treatment (Non-Compensation)': 10,
    'Initial Eligibility and Enrollment in VHA Healthcare': 14,
    'Caregiver | Other': 9,
    'Foreign Medical Program': 13,
    'Camp Lejune Family Member': 8
  },
  incomplete_issue_types: {},
};
