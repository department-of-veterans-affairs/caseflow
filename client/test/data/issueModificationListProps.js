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
    benefitType: 'Veterans Health Administration',
    requestIssue: {
      id: '3311',
      benefitType: 'Veterans Health Administration',
      nonRatingIssueCategory: 'Beneficiary Travel',
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
    requestReason: 'This is the reason that the user entered for the requested Modification to this issue.',
    benefitType: 'Veterans Health Administration',
    requestIssue: {
      id: '3311',
      benefitType: 'Veterans Health Administration',
      nonRatingIssueCategory: 'Beneficiary Travel',
      nonRatingIssueDescription: 'Stuff',
      decisionDate: '2023-09-23'
    }
  }
];

export const mockedAdditionRequestTypeProps = [
  {
    request_type: 'Addition',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonrating_issue_category: 'Beneficiary Travel',
    nonrating_issue_description: 'Money for Travel',
    decision_text: 'New note for this type of issue',
    decision_date: '2024-01-30',
    request_reason: 'This is the reason that the user entered for the requested Addition to this issue.',
    status: 'approved',
    benefit_type: 'Veterans Health Administration'
  }
];

export const mockedRemovalRequestTypeProps = [
  {
    request_issue_id: '3311',
    request_type: 'Removal',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonrating_issue_category: 'Caregiver | Eligibility',
    nonrating_issue_description: 'Money for Care',
    decision_text: 'New Caregiver | Eligibility text',
    decision_date: '2024-01-30',
    request_reason: 'This is the reason that the user entered for the requested Removal to this issue.',
    status: 'approved',
    benefit_type: 'Veterans Health Administration'
  }
];

export const mockedWithdrawalRequestTypeProps = [
  {
    request_issue_id: '3311',
    request_type: 'Withdrawal',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonrating_issue_category: 'Caregiver | Eligibility',
    nonrating_issue_description: 'Money for Care',
    decision_text: 'New Caregiver | Eligibility text',
    decision_date: '2024-01-30',
    withdrawal_date: '2024-01-30',
    request_reason: 'This is the reason that the user entered for the requested Withdrawal to this issue.',
    status: 'approved',
    benefit_type: 'Veterans Health Administration'
  }
];
