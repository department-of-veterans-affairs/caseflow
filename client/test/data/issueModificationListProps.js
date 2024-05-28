export const mockedModificationRequestProps = [
  {
    requestIssue_Id: '3311',
    requestType: 'Modification',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonRatingIssueCategory: 'Caregiver | Eligibility',
    nonRatingIssueDescription: 'Money for Care',
    decisionText: 'New Caregiver | Eligibility text',
    decisionDate: '2024-01-30',
    requestReason: 'This is the reason that the user entered for the requested Modification to this issue.',
    status: 'approved',
    removeOriginalIssue: true,
    benefitType: 'vha',
    requestIssue: {
      id: '3311',
      benefitType: 'vha',
      category: 'Beneficiary Travel',
      nonRatingIssueDescription: 'Stuff',
      decisionDate: '2023-09-23'
    }
  },
  {
    requestIssueId: '3311',
    requestType: 'Modification',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonRatingIssueCategory: 'CHAMPVA',
    nonRatingIssueDescription: 'Money for CHAMPVA',
    decisionText: 'New CHAMPVA text',
    decisionDate: '2024-01-30',
    requestReason: 'Reasoning for requested Modification to this issue.',
    benefitType: 'vha',
    requestIssue: {
      id: '3311',
      benefitType: 'vha',
      category: 'Beneficiary Travel',
      nonRatingIssueDescription: 'Stuff',
      decisionDate: '2023-09-23'
    }
  }
];

export const mockedAdditionRequestTypeProps = [
  {
    requestType: 'Addition',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonRatingIssueCategory: 'Beneficiary Travel',
    nonRatingIssueDescription: 'Money for Travel',
    decisionText: 'New note for this type of issue',
    decisionDate: '2024-01-30',
    requestReason: 'Reasoning for requested Modification to this issue.',
    status: 'approved',
    benefitType: 'vha'
  }
];

export const mockedRemovalRequestTypeProps = [
  {
    requestIssueId: '3311',
    requestType: 'Removal',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonRatingIssueCategory: 'Caregiver | Eligibility',
    nonRatingIssueDescription: 'Money for Care',
    decisionText: 'New Caregiver | Eligibility text',
    decisionDate: '2024-01-30',
    requestReason: 'Reasoning for requested Modification to this issue.',
    status: 'approved',
    benefitType: 'vha'
  }
];

export const mockedWithdrawalRequestTypeProps = [
  {
    requestIssueId: '3311',
    requestType: 'Withdrawal',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonRatingIssueCategory: 'Caregiver | Eligibility',
    nonRatingIssueDescription: 'Money for Care',
    decisionText: 'New Caregiver | Eligibility text',
    decisionDate: '2023-11-30',
    withdrawalDate: '2024-01-30',
    requestReason: 'Reasoning for requested Modification to this issue.',
    status: 'approved',
    benefitType: 'vha'
  }
];
