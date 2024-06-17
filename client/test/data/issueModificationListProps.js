/* eslint-disable max-lines */
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

export const mockedEnhancedPendingIssueModificationProps = {
  claimant: '744220038',
  claimantType: 'veteran',
  claimantName: 'Bob Smithschimmel',
  veteranIsNotClaimant: false,
  processedInCaseflow: true,
  legacyOptInApproved: null,
  legacyAppeals: [],
  ratings: null,
  editIssuesUrl: '/higher_level_reviews/9deba558-5d52-4c2c-b7f3-1ccbd49078a2/edit',
  processedAt: '2024-06-03T15:18:00.367-04:00',
  veteranInvalidFields: null,
  requestIssues: [
    {
      id: 6969,
      rating_issue_reference_id: null,
      rating_issue_profile_date: null,
      rating_decision_reference_id: null,
      description: 'Caregiver | Other - VHA - Caregiver ',
      nonrating_issue_description: 'VHA - Caregiver ',
      contention_text: 'Caregiver | Other - VHA - Caregiver ',
      approx_decision_date: '2024-05-03',
      category: 'Caregiver | Other',
      notes: null,
      is_unidentified: null,
      ramp_claim_id: null,
      vacols_id: null,
      vacols_sequence_id: null,
      ineligible_reason: null,
      ineligible_due_to_id: null,
      decision_review_title: 'Higher-Level Review',
      title_of_active_review: null,
      contested_decision_issue_id: null,
      withdrawal_date: null,
      contested_issue_description: null,
      end_product_code: null,
      end_product_establishment_code: null,
      verified_unidentified_issue: null,
      editable: true,
      exam_requested: null,
      vacols_issue: null,
      end_product_cleared: null,
      benefit_type: 'vha',
      is_predocket_needed: null,
      mst_status: false,
      vbms_mst_status: false,
      pact_status: false,
      vbms_pact_status: false,
      mst_status_update_reason_notes: null,
      pact_status_update_reason_notes: null
    },
    {
      id: 6968,
      rating_issue_reference_id: null,
      rating_issue_profile_date: null,
      rating_decision_reference_id: null,
      description: 'Beneficiary Travel - Seeded issue',
      nonrating_issue_description: 'Seeded issue',
      contention_text: 'Beneficiary Travel - Seeded issue',
      approx_decision_date: '2024-05-03',
      category: 'Beneficiary Travel',
      notes: null,
      is_unidentified: null,
      ramp_claim_id: null,
      vacols_id: null,
      vacols_sequence_id: null,
      ineligible_reason: null,
      ineligible_due_to_id: null,
      decision_review_title: 'Higher-Level Review',
      title_of_active_review: null,
      contested_decision_issue_id: null,
      withdrawal_date: null,
      contested_issue_description: null,
      end_product_code: null,
      end_product_establishment_code: null,
      verified_unidentified_issue: null,
      editable: true,
      exam_requested: null,
      vacols_issue: null,
      end_product_cleared: null,
      benefit_type: 'vha',
      is_predocket_needed: null,
      mst_status: false,
      vbms_mst_status: false,
      pact_status: false,
      vbms_pact_status: false,
      mst_status_update_reason_notes: null,
      pact_status_update_reason_notes: null
    }
  ],
  taskInProgress: true,
  decisionIssues: [],
  activeNonratingRequestIssues: [],
  pendingIssueModificationRequests: [
    {
      id: '42',
      benefitType: 'vha',
      status: 'assigned',
      requestType: 'modification',
      removeOriginalIssue: false,
      nonratingIssueDescription: null,
      nonratingIssueCategory: 'Caregiver | Eligibility',
      decisionDate: '2024-05-19',
      decisionReason: null,
      requestReason: 'Aut voluptas eius culpa.',
      requestIssueId: 6968,
      withdrawalDate: null,
      requestIssue: {
        id: '6968',
        benefitType: 'vha',
        decisionDate: '2024-05-03',
        nonratingIssueCategory: 'Beneficiary Travel',
        nonratingIssueDescription: 'Seeded issue'
      },
      requestor: {
        id: '6443',
        fullName: 'Lauren Roth',
        cssId: 'CSSID2280048',
        stationID: '101'
      },
      identifier: '42'
    }
  ],
  contestableIssuesByDate: [],
  intakeUser: null,
  relationships: [
    {
      value: 'CLAIMANT_WITH_PVA_AS_VSO',
      fullName: 'Bob Vance',
      relationshipType: 'Spouse',
      displayText: 'Bob Vance, Spouse',
      defaultPayeeCode: '10'
    },
    {
      value: '1129318238',
      fullName: 'Cathy Smith',
      relationshipType: 'Child',
      displayText: 'Cathy Smith, Child',
      defaultPayeeCode: '11'
    },
    {
      value: 'no-such-pid',
      fullName: 'Tom Brady',
      relationshipType: 'Child',
      displayText: 'Tom Brady, Child',
      defaultPayeeCode: '11'
    }
  ],
  veteranValid: true,
  receiptDate: '2024/05/03',
  veteran: {
    name: 'Bob Smithschimmel',
    fileNumber: '744220076',
    formName: 'Smithschimmel, Bob',
    ssn: '291675190'
  },
  powerOfAttorneyName: 'Clarence Darrow',
  claimantRelationship: 'Veteran',
  asyncJobUrl: '/asyncable_jobs/HigherLevelReview/jobs/682',
  benefitType: 'vha',
  payeeCode: null,
  hasClearedRatingEp: false,
  hasClearedNonratingEp: false,
  informalConference: null,
  sameOffice: null,
  formType: 'higher_level_review',
  contestableIssues: {},
  claimId: '9deba558-5d52-4c2c-b7f3-1ccbd49078a2',
  featureToggles: {
    useAmaActivationDate: true,
    correctClaimReviews: true,
    covidTimelinessExemption: true
  },
  userCanWithdrawIssues: true,
  userCanEditIntakeIssues: false,
  userIsVhaAdmin: true,
  userCanRequestIssueUpdates: false,
  userCssId: 'ACBAUERVVHAH',
  userFullName: 'Susanna Bahringer DDS',
  addDecisionDateModalVisible: false,
  addIssuesModalVisible: false,
  nonRatingRequestIssueModalVisible: false,
  unidentifiedIssuesModalVisible: false,
  addedIssues: [
    {
      id: '6969',
      benefitType: 'vha',
      decisionIssueId: null,
      description: 'Caregiver | Other - VHA - Caregiver ',
      nonRatingIssueDescription: 'VHA - Caregiver ',
      decisionDate: '2024-05-03',
      ineligibleReason: null,
      ineligibleDueToId: null,
      decisionReviewTitle: 'Higher-Level Review',
      contentionText: 'Caregiver | Other - VHA - Caregiver ',
      vacolsId: null,
      vacolsSequenceId: null,
      vacolsIssue: null,
      endProductCleared: null,
      endProductCode: null,
      withdrawalDate: null,
      editable: true,
      examRequested: null,
      isUnidentified: null,
      notes: null,
      category: 'Caregiver | Other',
      index: null,
      isRating: false,
      ratingIssueReferenceId: null,
      ratingDecisionReferenceId: null,
      ratingIssueProfileDate: null,
      approxDecisionDate: '2024-05-03',
      titleOfActiveReview: null,
      rampClaimId: null,
      verifiedUnidentifiedIssue: null,
      isPreDocketNeeded: null,
      mstChecked: false,
      pactChecked: false,
      vbmsMstChecked: false,
      vbmsPactChecked: false
    },
    {
      id: '6968',
      benefitType: 'vha',
      decisionIssueId: null,
      description: 'Beneficiary Travel - Seeded issue',
      nonRatingIssueDescription: 'Seeded issue',
      decisionDate: '2024-05-03',
      ineligibleReason: null,
      ineligibleDueToId: null,
      decisionReviewTitle: 'Higher-Level Review',
      contentionText: 'Beneficiary Travel - Seeded issue',
      vacolsId: null,
      vacolsSequenceId: null,
      vacolsIssue: null,
      endProductCleared: null,
      endProductCode: null,
      withdrawalDate: null,
      editable: true,
      examRequested: null,
      isUnidentified: null,
      notes: null,
      category: 'Beneficiary Travel',
      index: null,
      isRating: false,
      ratingIssueReferenceId: null,
      ratingDecisionReferenceId: null,
      ratingIssueProfileDate: null,
      approxDecisionDate: '2024-05-03',
      titleOfActiveReview: null,
      rampClaimId: null,
      verifiedUnidentifiedIssue: null,
      isPreDocketNeeded: null,
      mstChecked: false,
      pactChecked: false,
      vbmsMstChecked: false,
      vbmsPactChecked: false
    }
  ],
  originalIssues: [
    {
      id: '6969',
      benefitType: 'vha',
      decisionIssueId: null,
      description: 'Caregiver | Other - VHA - Caregiver ',
      nonRatingIssueDescription: 'VHA - Caregiver ',
      decisionDate: '2024-05-03',
      ineligibleReason: null,
      ineligibleDueToId: null,
      decisionReviewTitle: 'Higher-Level Review',
      contentionText: 'Caregiver | Other - VHA - Caregiver ',
      vacolsId: null,
      vacolsSequenceId: null,
      vacolsIssue: null,
      endProductCleared: null,
      endProductCode: null,
      withdrawalDate: null,
      editable: true,
      examRequested: null,
      isUnidentified: null,
      notes: null,
      category: 'Caregiver | Other',
      index: null,
      isRating: false,
      ratingIssueReferenceId: null,
      ratingDecisionReferenceId: null,
      ratingIssueProfileDate: null,
      approxDecisionDate: '2024-05-03',
      titleOfActiveReview: null,
      rampClaimId: null,
      verifiedUnidentifiedIssue: null,
      isPreDocketNeeded: null,
      mstChecked: false,
      pactChecked: false,
      vbmsMstChecked: false,
      vbmsPactChecked: false
    },
    {
      id: '6968',
      benefitType: 'vha',
      decisionIssueId: null,
      description: 'Beneficiary Travel - Seeded issue',
      nonRatingIssueDescription: 'Seeded issue',
      decisionDate: '2024-05-03',
      ineligibleReason: null,
      ineligibleDueToId: null,
      decisionReviewTitle: 'Higher-Level Review',
      contentionText: 'Beneficiary Travel - Seeded issue',
      vacolsId: null,
      vacolsSequenceId: null,
      vacolsIssue: null,
      endProductCleared: null,
      endProductCode: null,
      withdrawalDate: null,
      editable: true,
      examRequested: null,
      isUnidentified: null,
      notes: null,
      category: 'Beneficiary Travel',
      index: null,
      isRating: false,
      ratingIssueReferenceId: null,
      ratingDecisionReferenceId: null,
      ratingIssueProfileDate: null,
      approxDecisionDate: '2024-05-03',
      titleOfActiveReview: null,
      rampClaimId: null,
      verifiedUnidentifiedIssue: null,
      isPreDocketNeeded: null,
      mstChecked: false,
      pactChecked: false,
      vbmsMstChecked: false,
      vbmsPactChecked: false
    }
  ],
  originalPendingIssueModificationRequests: [
    {
      id: '42',
      benefitType: 'vha',
      status: 'assigned',
      requestType: 'modification',
      removeOriginalIssue: false,
      nonratingIssueDescription: null,
      nonratingIssueCategory: 'Caregiver | Eligibility',
      decisionDate: '2024-05-19',
      decisionReason: null,
      requestReason: 'Aut voluptas eius culpa.',
      requestIssueId: 6968,
      withdrawalDate: null,
      requestIssue: {
        id: '6968',
        benefitType: 'vha',
        decisionDate: '2024-05-03',
        nonratingIssueCategory: 'Beneficiary Travel',
        nonratingIssueDescription: 'Seeded issue'
      },
      requestor: {
        id: '6443',
        fullName: 'Lauren Roth',
        cssId: 'CSSID2280048',
        stationID: '101'
      },
      identifier: '42'
    }
  ],
  requestStatus: {
    requestIssuesUpdate: 'NOT_STARTED'
  },
  requestIssuesUpdateErrorCode: null,
  afterIssues: null,
  beforeIssues: null,
  updatedIssues: null,
  editEpUpdateError: null,
  requestIssueModificationModalVisible: false,
  enhancedPendingIssueModification: [
    {
      requestIssueId: 6968,
      nonratingIssueCategory: 'Caregiver | Eligibility',
      nonratingIssueDescription: 'adadad',
      benefitType: 'vha',
      id: '42',
      status: 'approved',
      requestType: 'modification',
      removeOriginalIssue: true,
      decisionDate: '2024-05-19T06:00:00.000Z',
      decisionReason: null,
      requestReason: 'Aut voluptas eius culpadada.',
      withdrawalDate: null,
      requestIssue: {
        id: '6968',
        benefitType: 'vha',
        decisionDate: '2024-05-03',
        nonratingIssueCategory: 'Beneficiary Travel',
        nonratingIssueDescription: 'Seeded issue'
      },
      requestor: {
        id: '6443',
        fullName: 'Lauren Roth',
        cssId: 'CSSID2280048',
        stationID: '101'
      },
      decider: {
        fullName: 'Susanna Bahringer DDS',
        cssId: 'ACBAUERVVHAH'
      },
      identifier: '42'
    }
  ],
  confirmPendingRequestIssueModalVisible: true
};
