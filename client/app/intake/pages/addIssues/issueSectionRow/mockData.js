/* eslint-disable no-empty-function */
const issueSectionRowProps = {
  editPage: true,
  featureToggles: {},
  formType: 'test',
  intakeData: {},
  onClickIssueAction: () => {},
  sectionIssues: [
    {
      index: 0,
      id: '4277',
      text: 'Medical and Dental Care Reimbursement - Issue',
      benefitType: 'vha',
      date: '2023-07-11',
      decisionReviewTitle: 'Supplemental Claim',
      category: 'Medical and Dental Care Reimbursement',
      editable: true,
    },
  ],
  userCanWithdrawIssues: true,
  withdrawReview: false,
  showRequestIssueUpdateOptions: true
};

const intakeData = {
  userIsVhaAdmin: true,
  benefitType: 'vha',
  originalPendingIssueModificationRequests: [
    {
      id: '40',
      benefitType: 'vha',
      status: 'assigned',
      requestType: 'modification',
      removeOriginalIssue: false,
      nonratingIssueDescription: 'asdadadad',
      nonratingIssueCategory: 'Caregiver | Eligibility',
      decisionDate: '2024-05-06T08:06:48.224-04:00',
      decisionReason: null,
      requestReason: 'Consequatur eos sunt veritatis.',
      requestIssueId: 6887,
      withdrawalDate: null,
      requestIssue: {
        id: '6887',
        benefitType: 'vha',
        decisionDate: '2024-04-13',
        nonratingIssueCategory: 'Camp Lejune Family Member',
        nonratingIssueDescription: 'Seeded issue'
      },
      requestor: {
        id: '6385',
        fullName: 'Lauren Roth',
        cssId: 'CSSID6411050',
        stationID: '101'
      }
    }
  ]
};

const intakeDataNonAdmin = {
  ...intakeData,
  userIsVhaAdmin: false
};

const issueSectionRowDataProps = {
  ...issueSectionRowProps,
  [Object.keys(issueSectionRowProps)[3]]: { ...intakeData }
};

const issueSectionRowDataNonAdminProps = {
  ...issueSectionRowProps,
  [Object.keys(issueSectionRowProps)[3]]: { ...intakeDataNonAdmin }
};

export {
  issueSectionRowProps,
  issueSectionRowDataProps,
  issueSectionRowDataNonAdminProps
};
