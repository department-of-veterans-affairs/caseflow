import INTAKE_FORM_NAMES from '../../constants/INTAKE_FORM_NAMES.json';
import INTAKE_FORM_NAMES_SHORT from '../../constants/INTAKE_FORM_NAMES_SHORT.json';

export const FORM_TYPES = {
  RAMP_ELECTION: {
    key: 'ramp_election',
    name: INTAKE_FORM_NAMES.ramp_election,
    category: 'ramp',
    formName: 'rampElection'
  },
  RAMP_REFILING: {
    key: 'ramp_refiling',
    name: INTAKE_FORM_NAMES.ramp_refiling,
    category: 'ramp',
    formName: 'rampRefiling'
  },
  HIGHER_LEVEL_REVIEW: {
    key: 'higher_level_review',
    name: INTAKE_FORM_NAMES.higher_level_review,
    shortName: INTAKE_FORM_NAMES_SHORT.higher_level_review,
    category: 'ama',
    formName: 'higherLevelReview'
  },
  SUPPLEMENTAL_CLAIM: {
    key: 'supplemental_claim',
    name: INTAKE_FORM_NAMES.supplemental_claim,
    shortName: INTAKE_FORM_NAMES_SHORT.supplemental_claim,
    category: 'ama',
    formName: 'supplementalClaim'
  },
  APPEAL: {
    key: 'appeal',
    name: INTAKE_FORM_NAMES.appeal,
    shortName: INTAKE_FORM_NAMES_SHORT.appeal,
    category: 'ama',
    formName: 'appeal'
  }
};

export const PAGE_PATHS = {
  BEGIN: '/',
  SEARCH: '/search',
  REVIEW: '/review_request',
  FINISH: '/finish',
  ADD_ISSUES: '/add_issues',
  COMPLETED: '/completed',
  CANCEL_ISSUES: '/cancel',
  CONFIRMATION: '/confirmation',
  DTA_CLAIM: '/dta',
  CLEARED_EPS: '/cleared_eps'
};

export const BOOLEAN_RADIO_OPTIONS = [
  { value: 'false',
    displayText: 'No' },
  { value: 'true',
    displayText: 'Yes' }
];

const issueCategoriesArray = [
  // Unknown issue category should be removed in the new add issues flow
  'Unknown issue category',
  'Apportionment',
  'Incarceration Adjustments',
  'Audit Error Worksheet (DFAS)',
  'Active Duty Adjustments',
  'Drill Pay Adjustments',
  'Character of discharge determinations',
  'Income/net worth (pension)',
  'Dependent child - Adopted',
  'Dependent child - Stepchild',
  'Dependent child - Biological',
  'Dependency Spouse - Common law marriage',
  'Dependency Spouse - Inference of marriage',
  'Dependency Spouse - Deemed valid marriage',
  'Military Retired Pay',
  'Contested Claims (other than apportionment)',
  'Lack of Qualifying Service',
  'Other non-rated'
];

export const ISSUE_CATEGORIES = issueCategoriesArray.map((category) => {
  return {
    value: category,
    label: category
  };
});

// Removes the "Unknown issue category"
// which is temporary until we activate the new "Add issues" flow
export const NONRATING_REQUEST_ISSUE_CATEGORIES = issueCategoriesArray.
  filter((category) => category !== 'Unknown issue category').map((category) => {
    return {
      value: category,
      label: category
    };
  });

export const REQUEST_STATE = {
  NOT_STARTED: 'NOT_STARTED',
  IN_PROGRESS: 'IN_PROGRESS',
  SUCCEEDED: 'SUCCEEDED',
  FAILED: 'FAILED'
};

export const ACTIONS = {
  SET_FORM_TYPE: 'SET_FORM_TYPE',
  START_NEW_INTAKE: 'START_NEW_INTAKE',
  SET_FILE_NUMBER_SEARCH: 'SET_FILE_NUMBER_SEARCH',
  FILE_NUMBER_SEARCH_START: 'FILE_NUMBER_SEARCH_START',
  FILE_NUMBER_SEARCH_SUCCEED: 'FILE_NUMBER_SEARCH_SUCCEED',
  FILE_NUMBER_SEARCH_FAIL: 'FILE_NUMBER_SEARCH_FAIL',
  CLEAR_SEARCH_ERRORS: 'CLEAR_SEARCH_ERRORS',
  SET_OPTION_SELECTED: 'SET_OPTION_SELECTED',
  SET_INFORMAL_CONFERENCE: 'SET_INFORMAL_CONFERENCE',
  SET_SAME_OFFICE: 'SET_SAME_OFFICE',
  SET_BENEFIT_TYPE: 'SET_BENEFIT_TYPE',
  SET_RECEIPT_DATE: 'SET_RECEIPT_DATE',
  SET_CLAIMANT_NOT_VETERAN: 'SET_CLAIMANT_NOT_VETERAN',
  SET_CLAIMANT: 'SET_CLAIMANT',
  SET_PAYEE_CODE: 'SET_PAYEE_CODE',
  SET_LEGACY_OPT_IN_APPROVED: 'SET_LEGACY_OPT_IN_APPROVED',
  SET_APPEAL_DOCKET: 'SET_APPEAL_DOCKET',
  SET_DOCKET_TYPE: 'SET_DOCKET_TYPE',
  TOGGLE_CANCEL_MODAL: 'TOGGLE_CANCEL_MODAL',
  TOGGLE_ADD_ISSUES_MODAL: 'TOGGLE_ADD_ISSUES_MODAL',
  TOGGLE_NONRATING_REQUEST_ISSUE_MODAL: 'TOGGLE_NONRATING_REQUEST_ISSUE_MODAL',
  TOGGLE_UNIDENTIFIED_ISSUES_MODAL: 'TOGGLE_UNIDENTIFIED_ISSUES_MODAL',
  TOGGLE_UNTIMELY_EXEMPTION_MODAL: 'TOGGLE_UNTIMELY_EXEMPTION_MODAL',
  TOGGLE_ISSUE_REMOVE_MODAL: 'TOGGLE_ISSUE_REMOVE_MODAL',
  SUBMIT_REVIEW_START: 'SUBMIT_REVIEW_START',
  SUBMIT_REVIEW_SUCCEED: 'SUBMIT_REVIEW_SUCCEED',
  SUBMIT_REVIEW_FAIL: 'SUBMIT_REVIEW_FAIL',
  SUBMIT_ERROR_FAIL: 'SUBMIT_ERROR_FAIL',
  COMPLETE_INTAKE_START: 'COMPLETE_INTAKE_START',
  COMPLETE_INTAKE_SUCCEED: 'COMPLETE_INTAKE_SUCCEED',
  COMPLETE_INTAKE_FAIL: 'COMPLETE_INTAKE_FAIL',
  CANCEL_INTAKE_START: 'CANCEL_INTAKE_START',
  CANCEL_INTAKE_SUCCEED: 'CANCEL_INTAKE_SUCCEED',
  CANCEL_INTAKE_FAIL: 'CANCEL_INTAKE_FAIL',
  CONFIRM_FINISH_INTAKE: 'CONFIRM_FINISH_INTAKE',
  COMPLETE_INTAKE_NOT_CONFIRMED: 'COMPLETE_INTAKE_NOT_CONFIRMED',
  SET_ISSUE_SELECTED: 'SET_ISSUE_SELECTED',
  ADD_ISSUE: 'ADD_ISSUE',
  REMOVE_ISSUE: 'REMOVE_ISSUE',
  ADD_NONRATING_REQUEST_ISSUE: 'ADD_NONRATING_REQUEST_ISSUE',
  NEW_NONRATING_REQUEST_ISSUE: 'NEW_NONRATING_REQUEST_ISSUE',
  SET_ISSUE_CATEGORY: 'SET_ISSUE_CATEGORY',
  SET_ISSUE_DESCRIPTION: 'SET_ISSUE_DESCRIPTION',
  SET_ISSUE_DECISION_DATE: 'SET_ISSUE_DECISION_DATE',
  SET_HAS_INELIGIBLE_ISSUE: 'SET_HAS_INELIGIBLE_ISSUE',
  CONFIRM_INELIGIBLE_FORM: 'CONFIRM_INELIGIBLE_FORM',
  CONFIRM_OUTSIDE_CASEFLOW_STEPS: 'CONFIRM_OUTSIDE_CASEFLOW_STEPS',
  COMPLETE_INTAKE_STEPS_NOT_CONFIRMED: 'COMPLETE_INTAKE_STEPS_NOT_CONFIRMED',
  PROCESS_FINISH_ERROR: 'PROCESS_FINISH_ERROR',
  NO_ISSUES_SELECTED_ERROR: 'NO_ISSUES_SELECTED_ERROR'
};

export const INTAKE_STATES = {
  NONE: 'NONE',
  STARTED: 'STARTED',
  REVIEWED: 'REVIEWED',
  COMPLETED: 'COMPLETED'
};

export const REVIEW_OPTIONS = {
  SUPPLEMENTAL_CLAIM: {
    key: 'supplemental_claim',
    name: 'Supplemental Claim'
  },
  HIGHER_LEVEL_REVIEW: {
    key: 'higher_level_review',
    name: 'Higher-Level Review'
  },
  HIGHER_LEVEL_REVIEW_WITH_HEARING: {
    key: 'higher_level_review_with_hearing',
    name: 'Higher-Level Review with Informal Conference'
  },
  APPEAL: {
    key: 'appeal',
    name: 'Appeal to Board'
  }
};

export const ENDPOINT_NAMES = {
  START_INTAKE: 'start-intake',
  REVIEW_INTAKE: 'review-intake',
  CANCEL_INTAKE: 'cancel-intake',
  COMPLETE_INTAKE: 'complete-intake',
  ERROR_INTAKE: 'error-intake'
};

export const CANCELLATION_REASONS = {
  DUPLICATE_EP: {
    key: 'duplicate_ep',
    name: 'Duplicate EP created outside Caseflow'
  },
  SYSTEM_ERROR: {
    key: 'system_error',
    name: 'System error'
  },
  MISSING_SIGNATURE: {
    key: 'missing_signature',
    name: 'Missing signature'
  },
  VETERAN_CLARIFICATION: {
    key: 'veteran_clarification',
    name: 'Need clarification from Veteran'
  },
  OTHER: {
    key: 'other',
    name: 'Other'
  }
};

export const PAYEE_CODES = [
  { value: '00',
    label: '00 - Veteran' },
  { value: '01',
    label: '01 - First Payee Recipient' },
  { value: '02',
    label: '02 - Second Payee Recipient' },
  { value: '03',
    label: '03 - Third Payee Recipient' },
  { value: '04',
    label: '04 - Fourth Payee Recipient' },
  { value: '05',
    label: '05 - Fifth Payee Recipient' },
  { value: '06',
    label: '06 - Sixth Payee Recipient' },
  { value: '07',
    label: '07 - Seventh Payee Recipient' },
  { value: '08',
    label: '08 - Eighth Payee Recipient' },
  { value: '09',
    label: '09 - Ninth Payee Recipient' },
  { value: '10',
    label: '10 - Spouse' },
  { value: '11',
    label: '11 - C&P First Child' },
  { value: '12',
    label: '12 - C&P Second Child' },
  { value: '13',
    label: '13 - C&P Third Child' },
  { value: '14',
    label: '14 - C&P Fourth Child' },
  { value: '15',
    label: '15 - C&P Fifth Child' },
  { value: '16',
    label: '16 - C&P Sixth Child' },
  { value: '17',
    label: '17 - C&P Seventh Child' },
  { value: '18',
    label: '18 - C&P Eighth Child' },
  { value: '19',
    label: '19 - C&P Ninth Child' },
  { value: '20',
    label: '20 - C&P Tenth Child' },
  { value: '21',
    label: '21 - C&P Eleventh Child' },
  { value: '22',
    label: '22 - C&P Twelfth Child' },
  { value: '23',
    label: '23 - C&P Thirteenth Child' },
  { value: '24',
    label: '24 - C&P Fourteenth Child' },
  { value: '25',
    label: '25 - C&P Fifteenth Child' },
  { value: '26',
    label: '26 - C&P Sixteenth Child' },
  { value: '27',
    label: '27 - C&P Seventeenth Child' },
  { value: '28',
    label: '28 - C&P Eighteenth Child' },
  { value: '29',
    label: '29 - C&P Nineteenth Child' },
  { value: '30',
    label: '30 - Vendor' },
  { value: '31',
    label: '31 - Consolidated Payee 1st group of children' },
  { value: '32',
    label: '32 - Consolidated Payee 2nd group of children' },
  { value: '33',
    label: '33 - Consolidated Payee 3rd group of children' },
  { value: '34',
    label: '34 - Consolidated Payee 4th group of children' },
  { value: '35',
    label: '35 - Consolidated Payee 5th group of children' },
  { value: '36',
    label: '36 - Consolidated Payee 6th group of children' },
  { value: '37',
    label: '37 - Consolidated Payee 7th group of children' },
  { value: '38',
    label: '38 - Consolidated Payee 8th group of children' },
  { value: '39',
    label: '39 - Consolidated Payee 9th group of children' },
  { value: '41',
    label: '41 - CH35 First Child' },
  { value: '42',
    label: '42 - CH35 Second Child' },
  { value: '43',
    label: '43 - CH35 Third Child' },
  { value: '44',
    label: '44 - CH35 Fourth Child' },
  { value: '45',
    label: '45 - CH35 Fifth Child' },
  { value: '46',
    label: '46 - CH35 Sixth Child' },
  { value: '47',
    label: '47 - CH35 Seventh Child' },
  { value: '48',
    label: '48 - CH35 Eighth Child' },
  { value: '49',
    label: '49 - CH35 Ninth Child' },
  { value: '50',
    label: '50 - Dependent Father' },
  { value: '60',
    label: '60 - Dependent Mother' },
  { value: '70',
    label: '70 - DIC Award 38 USC412(a) First Payee' },
  { value: '71',
    label: '71 - DIC Award 38 USC412(a) Second Payee' },
  { value: '72',
    label: '72 - DIC Award 38 USC412(a) Third Payee' },
  { value: '73',
    label: '73 - DIC Award 38 USC412(a) Fourth Payee' },
  { value: '74',
    label: '74 - DIC Award 38 USC412(a) Fifth Payee' },
  { value: '75',
    label: '75 - DIC Award 38 USC412(a) Sixth Payee' },
  { value: '76',
    label: '76 - DIC Award 38 USC412(a) Seventh Payee' },
  { value: '77',
    label: '77 - DIC Award 38 USC412(a) Eighth Payee' },
  { value: '78',
    label: '78 - DIC Award 38 USC412(a) Ninth Payee' },
  { value: '80',
    label: '80 - First Claimant Burial/Accrued' },
  { value: '81',
    label: '81 - Second Claimant Burial/Accrued' },
  { value: '82',
    label: '82 - Third Claimant Burial/Accrued' },
  { value: '83',
    label: '83 - Fourth Claimant Burial/Accrued' },
  { value: '84',
    label: '84 - Fifth Claimant Burial/Accrued' },
  { value: '85',
    label: '85 - Sixth Claimant Burial/Accrued' },
  { value: '86',
    label: '86 - Seventh Claimant Burial/Accrued' },
  { value: '87',
    label: '87 - Eighth Claimant Burial/Accrued' },
  { value: '88',
    label: '88 - Ninth Claimant Burial/Accrued' },
  { value: '89',
    label: '89 - Tenth Claimant Burial/Accrued' },
  { value: '99',
    label: '99 - Institutional Veteran CFR3.852' }
];
