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

const PAYEE_CODES = {
  '00': '00 - Veteran',
  '01': '01 - First Payee Recipient',
  '02': '02 - Second Payee Recipient',
  '03': '03 - Third Payee Recipient',
  '04': '04 - Fourth Payee Recipient',
  '05': '05 - Fifth Payee Recipient',
  '06': '06 - Sixth Payee Recipient',
  '07': '07 - Seventh Payee Recipient',
  '08': '08 - Eighth Payee Recipient',
  '09': '09 - Ninth Payee Recipient',
  10: '10 - Spouse',
  11: '11 - C&P First Child',
  12: '12 - C&P Second Child',
  13: '13 - C&P Third Child',
  14: '14 - C&P Fourth Child',
  15: '15 - C&P Fifth Child',
  16: '16 - C&P Sixth Child',
  17: '17 - C&P Seventh Child',
  18: '18 - C&P Eighth Child',
  19: '19 - C&P Ninth Child',
  20: '20 - C&P Tenth Child',
  21: '21 - C&P Eleventh Child',
  22: '22 - C&P Twelfth Child',
  23: '23 - C&P Thirteenth Child',
  24: '24 - C&P Fourteenth Child',
  25: '25 - C&P Fifteenth Child',
  26: '26 - C&P Sixteenth Child',
  27: '27 - C&P Seventeenth Child',
  28: '28 - C&P Eighteenth Child',
  29: '29 - C&P Nineteenth Child',
  30: '30 - Vendor',
  31: '31 - Consolidated Payee 1st group of children',
  32: '32 - Consolidated Payee 2nd group of children',
  33: '33 - Consolidated Payee 3rd group of children',
  34: '34 - Consolidated Payee 4th group of children',
  35: '35 - Consolidated Payee 5th group of children',
  36: '36 - Consolidated Payee 6th group of children',
  37: '37 - Consolidated Payee 7th group of children',
  38: '38 - Consolidated Payee 8th group of children',
  39: '39 - Consolidated Payee 9th group of children',
  41: '41 - CH35 First Child',
  42: '42 - CH35 Second Child',
  43: '43 - CH35 Third Child',
  44: '44 - CH35 Fourth Child',
  45: '45 - CH35 Fifth Child',
  46: '46 - CH35 Sixth Child',
  47: '47 - CH35 Seventh Child',
  48: '48 - CH35 Eighth Child',
  49: '49 - CH35 Ninth Child',
  50: '50 - Dependent Father',
  60: '60 - Dependent Mother',
  70: '70 - DIC Award 38 USC412(a) First Payee',
  71: '71 - DIC Award 38 USC412(a) Second Payee',
  72: '72 - DIC Award 38 USC412(a) Third Payee',
  73: '73 - DIC Award 38 USC412(a) Fourth Payee',
  74: '74 - DIC Award 38 USC412(a) Fifth Payee',
  75: '75 - DIC Award 38 USC412(a) Sixth Payee',
  76: '76 - DIC Award 38 USC412(a) Seventh Payee',
  77: '77 - DIC Award 38 USC412(a) Eighth Payee',
  78: '78 - DIC Award 38 USC412(a) Ninth Payee',
  80: '80 - First Claimant Burial/Accrued',
  81: '81 - Second Claimant Burial/Accrued',
  82: '82 - Third Claimant Burial/Accrued',
  83: '83 - Fourth Claimant Burial/Accrued',
  84: '84 - Fifth Claimant Burial/Accrued',
  85: '85 - Sixth Claimant Burial/Accrued',
  86: '86 - Seventh Claimant Burial/Accrued',
  87: '87 - Eighth Claimant Burial/Accrued',
  88: '88 - Ninth Claimant Burial/Accrued',
  89: '89 - Tenth Claimant Burial/Accrued',
  99: '99 - Institutional Veteran CFR3.852'
};

const getValidPayeeCodes = (isDeceased) => {
  // got these from BGS find_payee_cds_by_bnft_claim_type_cd
  let validCodes = ['00', '10', '11', '12', '13', '14', '15', '16', '17',
    '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
    '31', '32', '33', '34', '35', '36', '37', '38', '39', '50', '60'];

  if (isDeceased) {
    validCodes = ['10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '31', '32',
      '33', '34', '35', '36', '37', '38', '39', '50', '60', '70', '71', '72',
      '73', '74', '75', '76', '77', '78'];
  }

  return validCodes.map((code) => {
    return { value: code,
      label: PAYEE_CODES[code] };
  });
};

// wrap in singleton so these are calculated once
export const DECEASED_PAYEE_CODES = (() => getValidPayeeCodes(true))();
export const LIVING_PAYEE_CODES = (() => getValidPayeeCodes(false))();
