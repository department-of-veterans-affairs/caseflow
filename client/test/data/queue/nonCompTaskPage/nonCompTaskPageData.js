/* eslint-disable max-lines */
const completedHLRTaskData = {
  businessLine: 'Veterans Health Administration',
  businessLineUrl: 'vha',
  baseTasksUrl: '/decision_reviews/vha',
  taskFilterDetails: {
    in_progress: {},
    completed: {
      '["DecisionReviewTask", "HigherLevelReview"]': 3,
      '["DecisionReviewTask", "SupplementalClaim"]': 1
    }
  },
  task: {
    claimant: {
      name: 'Bob Smithgreen',
      relationship: 'self'
    },
    appeal: {
      id: '17',
      isLegacyAppeal: false,
      issueCount: 1,
      activeRequestIssues: [
        {
          id: 3710,
          rating_issue_reference_id: null,
          rating_issue_profile_date: null,
          rating_decision_reference_id: null,
          description: 'Beneficiary Travel - sdad',
          contention_text: 'Beneficiary Travel - sdad',
          approx_decision_date: '2023-03-30',
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
          is_predocket_needed: null
        }
      ],
      appellant_type: null
    },
    power_of_attorney: {
      representative_type: 'Attorney',
      representative_name: 'Clarence Darrow',
      representative_address: {
        address_line_1: '9999 MISSION ST',
        address_line_2: 'UBER',
        address_line_3: 'APT 2',
        city: 'SAN FRANCISCO',
        zip: '94103',
        country: 'USA',
        state: 'CA'
      },
      representative_email_address: 'jamie.fakerton@caseflowdemo.com'
    },
    appellant_type: null,
    issue_count: 1,
    tasks_url: '/decision_reviews/vha',
    id: 10467,
    created_at: '2023-05-01T12:54:22.123-04:00',
    veteran_participant_id: '253956744',
    veteran_ssn: '800124578',
    assigned_on: '2023-05-01T12:54:22.123-04:00',
    assigned_at: '2023-05-01T12:54:22.123-04:00',
    closed_at: '2023-05-01T13:25:21.367-04:00',
    started_at: null,
    type: 'Higher-Level Review',
    business_line: 'vha'
  },
  appeal: {
    claimant: '253956744',
    claimantType: 'veteran',
    claimantName: 'Bob Smithgreen',
    veteranIsNotClaimant: false,
    processedInCaseflow: true,
    legacyOptInApproved: false,
    legacyAppeals: [],
    ratings: null,
    editIssuesUrl: '/higher_level_reviews/26e2dc68-c3c6-484d-8cfd-5075792d6eb9/edit',
    processedAt: null,
    veteranInvalidFields: {
      veteran_missing_fields: [],
      veteran_address_too_long: false,
      veteran_address_invalid_fields: false,
      veteran_city_invalid_fields: false,
      veteran_city_too_long: false,
      veteran_date_of_birth_invalid: false,
      veteran_name_suffix_invalid: false,
      veteran_zip_code_invalid: false,
      veteran_pay_grade_invalid: false
    },
    requestIssues: [
      {
        id: 3710,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Beneficiary Travel - sdad',
        contention_text: 'Beneficiary Travel - sdad',
        approx_decision_date: '2023-03-30',
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
        is_predocket_needed: null
      }
    ],
    decisionIssues: [
      {
        id: 756,
        description: 'granted',
        disposition: 'Granted',
        approxDecisionDate: '2023-04-01',
        requestIssueId: 3710
      }
    ],
    activeNonratingRequestIssues: [
      {
        id: 3708,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Entitlement | Parent - test',
        contention_text: 'Entitlement | Parent - test',
        approx_decision_date: '2023-04-18',
        category: 'Entitlement | Parent',
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
        benefit_type: 'nca',
        is_predocket_needed: null
      },
      {
        id: 3707,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Continuing Eligibility/Income Verification Match (IVM) - ad',
        contention_text: 'Continuing Eligibility/Income Verification Match (IVM) - ad',
        approx_decision_date: '2023-04-04',
        category: 'Continuing Eligibility/Income Verification Match (IVM)',
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
        is_predocket_needed: null
      },
      {
        id: 3706,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Testerereaa',
        contention_text: 'Testerereaa',
        approx_decision_date: '2023-04-03',
        category: 'Other',
        notes: null,
        is_unidentified: null,
        ramp_claim_id: null,
        vacols_id: null,
        vacols_sequence_id: null,
        ineligible_reason: null,
        ineligible_due_to_id: null,
        decision_review_title: 'Supplemental Claim',
        title_of_active_review: null,
        contested_decision_issue_id: 753,
        withdrawal_date: null,
        contested_issue_description: 'Testerereaa',
        end_product_code: null,
        end_product_establishment_code: null,
        verified_unidentified_issue: null,
        editable: true,
        exam_requested: null,
        vacols_issue: null,
        end_product_cleared: null,
        benefit_type: 'vha',
        is_predocket_needed: null
      },
      {
        id: 3705,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Other - test',
        contention_text: 'Other - test',
        approx_decision_date: '2023-03-30',
        category: 'Other',
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
        is_predocket_needed: null
      },
      {
        id: 3699,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Other Non-Rated - test',
        contention_text: 'Other Non-Rated - test',
        approx_decision_date: '2023-04-26',
        category: 'Other Non-Rated',
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
        end_product_code: '030HLRNR',
        end_product_establishment_code: '030HLRNR',
        verified_unidentified_issue: null,
        editable: true,
        exam_requested: null,
        vacols_issue: null,
        end_product_cleared: false,
        benefit_type: 'compensation',
        is_predocket_needed: null
      },
      {
        id: 3697,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Prosthetics | Other (not clothing allowance) - test',
        contention_text: 'Prosthetics | Other (not clothing allowance) - test',
        approx_decision_date: '2023-04-12',
        category: 'Prosthetics | Other (not clothing allowance)',
        notes: null,
        is_unidentified: null,
        ramp_claim_id: null,
        vacols_id: null,
        vacols_sequence_id: null,
        ineligible_reason: null,
        ineligible_due_to_id: null,
        decision_review_title: 'Appeal',
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
        is_predocket_needed: true
      }
    ],
    contestableIssuesByDate: [
      {
        ratingIssueReferenceId: null,
        ratingIssueProfileDate: null,
        ratingIssueDiagnosticCode: null,
        ratingDecisionReferenceId: null,
        decisionIssueId: 756,
        approxDecisionDate: '2023-04-01',
        description: 'granted',
        rampClaimId: null,
        titleOfActiveReview: null,
        sourceReviewType: null,
        timely: true,
        latestIssuesInChain: [
          {
            id: 756,
            approxDecisionDate: '2023-04-01'
          }
        ],
        isRating: false
      },
    ],
    intakeUser: 'ACBAUERVVHAH',
    relationships: [
      {
        participant_id: 'CLAIMANT_WITH_PVA_AS_VSO',
        first_name: 'BOB',
        last_name: 'VANCE',
        relationship_type: 'Spouse',
        default_payee_code: '10'
      },
      {
        participant_id: '1129318238',
        first_name: 'CATHY',
        last_name: 'SMITH',
        relationship_type: 'Child',
        default_payee_code: '11'
      },
      {
        participant_id: 'no-such-pid',
        first_name: 'TOM',
        last_name: 'BRADY',
        relationship_type: 'Child',
        default_payee_code: '11'
      }
    ],
    veteranValid: true,
    receiptDate: '2023/04/03',
    veteran: {
      name: 'Bob Smithgreen',
      fileNumber: '000100000',
      formName: 'Smithgreen, Bob',
      ssn: '800124578'
    },
    powerOfAttorneyName: 'Clarence Darrow',
    claimantRelationship: 'Veteran',
    asyncJobUrl: '/asyncable_jobs/HigherLevelReview/jobs/17',
    benefitType: 'vha',
    payeeCode: null,
    hasClearedRatingEp: false,
    hasClearedNonratingEp: false,
    informalConference: false,
    sameOffice: null,
    formType: 'higher_level_review'
  },
  selectedTask: null,
  decisionIssuesStatus: {},
  powerOfAttorneyName: null,
  poaAlert: {},
  featureToggles: {
    decisionReviewQueueSsnColumn: true
  },
  loadingPowerOfAttorney: {
    loading: false
  },
  ui: {
    featureToggles: {
      poa_button_refresh: true
    }
  },
  vhaAdmin: false
};

const genericTaskData = {
  businessLine: 'National Cemetery Administration',
  businessLineUrl: 'nca',
  businessLineConfig: {
    tabs: [
      'in_progress',
      'completed'
    ]
  },
  baseTasksUrl: '/decision_reviews/nca',
  taskFilterDetails: {
    in_progress: {
      '["BoardGrantEffectuationTask", "Appeal"]': 6,
      '["DecisionReviewTask", "HigherLevelReview"]': 21,
      '["DecisionReviewTask", "SupplementalClaim"]': 15
    },
    in_progress_issue_types: {
      'Entitlement | Spouse/Surving Spouse': 2,
      'Entitlement | Hmong': 1,
      Apportionment: 27,
      'Entitlement | Medallion (No Grave)': 1,
      'Entitlement | Medallion (Monetary Allowance)': 1,
      'Entitlement | Confederate IMO': 4,
      'Entitlement | No Military Information': 1,
      'Entitlement | Other': 1,
      'Entitlement | Merchant Marine': 1,
      'Entitlement | Pre-Need': 2,
      'Entitlement | ABMC/Overseas Burial': 1,
      'Entitlement | Allied Forces and Non-Citizens': 1,
      'Entitlement | IMO in NC': 1,
      'Entitlement | Voided Enlistment': 1,
      'Entitlement | Benefit Already Provided': 1,
      'Entitlement | Cadet (Service Academies)': 2,
      'Entitlement | Pre-WWI/Burial Site Unknown': 1,
      'Entitlement | Reserves/National Guard': 1,
      'Entitlement | Character of Service': 3,
      'Entitlement | Cremains Not Interred': 3,
      'Entitlement | Unauthorized Applicant': 1,
      'Entitlement | Historic Marker Deemed Serviceable': 0,
      'Entitlement | Less than 24 Months': 0,
      'Entitlement | Marked Grave (Death on/after 10-18-78 to 10-31-90)': 0,
      'Entitlement | Marked Grave (Death prior to 10-18-78)': 0,
      'Entitlement | Medallion (Unmarked Grave)': 0,
      'Entitlement | Non-Qualifying Service': 0,
      'Entitlement | Parent': 0,
      'Entitlement | Replacement': 0,
      'Entitlement | Unmarried Adult Child': 0
    },
    completed: {},
    completed_issue_types: {
      'Entitlement | ABMC/Overseas Burial': 0,
      'Entitlement | Allied Forces and Non-Citizens': 0,
      'Entitlement | Benefit Already Provided': 0,
      'Entitlement | Cadet (Service Academies)': 0,
      'Entitlement | Character of Service': 0,
      'Entitlement | Confederate IMO': 0,
      'Entitlement | Cremains Not Interred': 0,
      'Entitlement | Historic Marker Deemed Serviceable': 0,
      'Entitlement | Hmong': 0,
      'Entitlement | IMO in NC': 0,
      'Entitlement | Less than 24 Months': 0,
      'Entitlement | Marked Grave (Death on/after 10-18-78 to 10-31-90)': 0,
      'Entitlement | Marked Grave (Death prior to 10-18-78)': 0,
      'Entitlement | Medallion (Monetary Allowance)': 0,
      'Entitlement | Medallion (No Grave)': 0,
      'Entitlement | Medallion (Unmarked Grave)': 0,
      'Entitlement | Merchant Marine': 0,
      'Entitlement | No Military Information': 0,
      'Entitlement | Non-Qualifying Service': 0,
      'Entitlement | Other': 0,
      'Entitlement | Parent': 0,
      'Entitlement | Pre-WWI/Burial Site Unknown': 0,
      'Entitlement | Pre-Need': 0,
      'Entitlement | Replacement': 0,
      'Entitlement | Reserves/National Guard': 0,
      'Entitlement | Spouse/Surving Spouse': 0,
      'Entitlement | Unauthorized Applicant': 0,
      'Entitlement | Unmarried Adult Child': 0,
      'Entitlement | Voided Enlistment': 0
    }
  },
  task: {
    has_poa: true,
    claimant: {
      name: 'Jane Smith',
      relationship: 'Child'
    },
    appeal: {
      id: '121',
      uuid: '16760c26-66e2-439a-afad-8133bff07c14',
      isLegacyAppeal: false,
      issueCount: 1,
      activeRequestIssues: [
        {
          id: 3323,
          rating_issue_reference_id: null,
          rating_issue_profile_date: null,
          rating_decision_reference_id: null,
          description: 'Entitlement | Medallion (Monetary Allowance) - National Cemetery Administration Seeded issue',
          nonrating_issue_description: 'National Cemetery Administration Seeded issue',
          contention_text: 'Entitlement | Medallion (Monetary Allowance) - National Cemetery Administration Seeded issue',
          approx_decision_date: '2023-08-12',
          category: 'Entitlement | Medallion (Monetary Allowance)',
          notes: null,
          is_unidentified: null,
          ramp_claim_id: null,
          vacols_id: null,
          vacols_sequence_id: null,
          ineligible_reason: null,
          ineligible_due_to_id: null,
          decision_review_title: 'Supplemental Claim',
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
          benefit_type: 'nca',
          is_predocket_needed: null
        }
      ],
      appellant_type: 'OtherClaimant'
    },
    power_of_attorney: {
      representative_type: 'Unrecognized representative',
      representative_name: 'Jane Smith',
      representative_address: {
        address_line_1: '123 Park Ave',
        address_line_2: null,
        address_line_3: null,
        city: 'Springfield',
        state: 'NY',
        zip: '12345',
        country: 'USA'
      },
      representative_email_address: null,
      poa_last_synced_at: '2023-09-12T05:58:40.415-04:00',
      representative_tz: 'America/New_York'
    },
    appellant_type: 'OtherClaimant',
    issue_count: 1,
    issue_types: 'Entitlement | Medallion (Monetary Allowance)',
    tasks_url: '/decision_reviews/nca',
    id: 9690,
    created_at: '2023-09-12T05:58:40.500-04:00',
    veteran_participant_id: '451277479',
    veteran_ssn: '775034184',
    assigned_on: '2023-09-12T05:58:40.497-04:00',
    assigned_at: '2023-09-12T05:58:40.497-04:00',
    closed_at: null,
    started_at: null,
    type: 'Supplemental Claim',
    external_appeal_id: '16760c26-66e2-439a-afad-8133bff07c14',
    appeal_type: 'SupplementalClaim',
    business_line: 'nca'
  },
  appeal: {
    claimant: '451277479',
    claimantType: 'other',
    claimantName: 'Jane Smith',
    veteranIsNotClaimant: true,
    processedInCaseflow: true,
    legacyOptInApproved: null,
    legacyAppeals: [],
    ratings: null,
    editIssuesUrl: '/supplemental_claims/16760c26-66e2-439a-afad-8133bff07c14/edit',
    processedAt: '2023-09-12T05:58:40.306-04:00',
    veteranInvalidFields: null,
    requestIssues: [
      {
        id: 3323,
        rating_issue_reference_id: null,
        rating_issue_profile_date: null,
        rating_decision_reference_id: null,
        description: 'Entitlement | Medallion (Monetary Allowance) - National Cemetery Administration Seeded issue',
        nonrating_issue_description: 'National Cemetery Administration Seeded issue',
        contention_text: 'Entitlement | Medallion (Monetary Allowance) - National Cemetery Administration Seeded issue',
        approx_decision_date: '2023-08-12',
        category: 'Entitlement | Medallion (Monetary Allowance)',
        notes: null,
        is_unidentified: null,
        ramp_claim_id: null,
        vacols_id: null,
        vacols_sequence_id: null,
        ineligible_reason: null,
        ineligible_due_to_id: null,
        decision_review_title: 'Supplemental Claim',
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
        benefit_type: 'nca',
        is_predocket_needed: null
      }
    ],
    decisionIssues: [],
    activeNonratingRequestIssues: [],
    contestableIssuesByDate: [],
    intakeUser: null,
    relationships: [
      {
        participant_id: 'CLAIMANT_WITH_PVA_AS_VSO',
        first_name: 'BOB',
        last_name: 'VANCE',
        relationship_type: 'Spouse',
        default_payee_code: '10'
      },
      {
        participant_id: '1129318238',
        first_name: 'CATHY',
        last_name: 'SMITH',
        relationship_type: 'Child',
        default_payee_code: '11'
      },
      {
        participant_id: 'no-such-pid',
        first_name: 'TOM',
        last_name: 'BRADY',
        relationship_type: 'Child',
        default_payee_code: '11'
      }
    ],
    veteranValid: true,
    receiptDate: '2023/08/12',
    veteran: {
      name: 'Bob Smithnader',
      fileNumber: '451274319',
      formName: 'Smithnader, Bob',
      ssn: '775034184'
    },
    powerOfAttorneyName: 'Jane Smith',
    claimantRelationship: 'Child',
    asyncJobUrl: '/asyncable_jobs/SupplementalClaim/jobs/121',
    benefitType: 'nca',
    payeeCode: null,
    hasClearedRatingEp: false,
    hasClearedNonratingEp: false,
    isDtaError: false,
    formType: 'supplemental_claim'
  },
  poaAlert: {},
  vhaAdmin: true,
  featureToggles: {
    decisionReviewQueueSsnColumn: true
  },
  loadingPowerOfAttorney: {
    loading: false,
    error: false
  },
  ui: {
    featureToggles: {
      poa_button_refresh: true
    }
  },
  selectedTask: null,
  decisionIssuesStatus: {}
};

export const completeTaskPageData = {
  serverNonComp: {
    ...completedHLRTaskData,
  },
};

export const genericTaskPageData = {
  serverNonComp: {
    ...genericTaskData
  },
};

export const genericTaskPageDataWithVhaAdmin = {
  serverNonComp: {
    ...genericTaskData,
    [Object.keys(genericTaskData)[8]]: true,
  },
};

export const inProgressTaskPageDataWithAdmin = {
  serverNonComp: {
    ...completedHLRTaskData,
    [Object.keys(completedHLRTaskData)[4]]: {
      ...Object.values(completedHLRTaskData)[4],
      closed_at: null,
    },
    [Object.keys(completedHLRTaskData)[5]]: {
      ...Object.values(completedHLRTaskData)[5],
      decisionIssues: [],
      contestableIssuesByDate: [],
    },
    [Object.keys(completedHLRTaskData)[13]]: true
  },
}

export const inProgressTaskPageData = {
  serverNonComp: {
    ...completedHLRTaskData,
    [Object.keys(completedHLRTaskData)[4]]: {
      ...Object.values(completedHLRTaskData)[4],
      closed_at: null,
    },
    [Object.keys(completedHLRTaskData)[5]]: {
      ...Object.values(completedHLRTaskData)[5],
      decisionIssues: [],
      contestableIssuesByDate: [],
    }
  },
};
/* eslint-enable max-len */
