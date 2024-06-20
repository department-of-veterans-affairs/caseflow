import COPY from '../../COPY';

export const mockedModificationRequestProps = [
  {
    requestIssue_Id: '3311',
    requestType: 'modification',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonratingIssueCategory: 'Caregiver | Eligibility',
    nonratingIssueDescription: 'Money for Care',
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
      nonratingIssueDescription: 'Stuff',
      decisionDate: '2023-09-23'
    }
  },
  {
    requestIssueId: '3311',
    requestType: 'modification',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonratingIssueCategory: 'CHAMPVA',
    nonratingIssueDescription: 'Money for CHAMPVA',
    decisionText: 'New CHAMPVA text',
    decisionDate: '2024-01-30',
    requestReason: 'Reasoning for requested Modification to this issue.',
    benefitType: 'vha',
    requestIssue: {
      id: '3311',
      benefitType: 'vha',
      category: 'Beneficiary Travel',
      nonratingIssueDescription: 'Stuff',
      decisionDate: '2023-09-23'
    }
  },
];

export const mockedAdditionRequestTypeProps = [
  {
    requestType: 'addition',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonratingIssueCategory: 'Beneficiary Travel',
    nonratingIssueDescription: 'Money for Travel',
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
    requestType: 'removal',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonratingIssueCategory: 'Caregiver | Eligibility',
    nonratingIssueDescription: 'Money for Care',
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
    requestType: 'withdrawal',
    requestor: 'Monte Mann (ACBAUERVVHA)',
    nonratingIssueCategory: 'Caregiver | Eligibility',
    nonratingIssueDescription: 'Money for Care',
    decisionText: 'New Caregiver | Eligibility text',
    decisionDate: '2023-11-30',
    withdrawalDate: '2024-01-30',
    requestReason: 'Reasoning for requested Modification to this issue.',
    status: 'approved',
    benefitType: 'vha'
  }
];

export const additionProps = {
  sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE,
  issueModificationRequests: mockedAdditionRequestTypeProps,
  onClickPendingIssueAction: jest.fn()
};

export const modificationProps = {
  sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE,
  issueModificationRequests: mockedModificationRequestProps,
  onClickPendingIssueAction: jest.fn()
};

export const removalProps = {
  sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE,
  issueModificationRequests: mockedRemovalRequestTypeProps,
  onClickPendingIssueAction: jest.fn()
};

export const withdrawalProps = {
  sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE,
  issueModificationRequests: mockedWithdrawalRequestTypeProps,
  onClickPendingIssueAction: jest.fn()
};
