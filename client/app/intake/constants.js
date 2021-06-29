import INTAKE_FORM_NAMES from '../../constants/INTAKE_FORM_NAMES';
import INTAKE_FORM_NAMES_SHORT from '../../constants/INTAKE_FORM_NAMES_SHORT';

export const FORM_TYPES = {
  APPEAL: {
    key: 'appeal',
    name: INTAKE_FORM_NAMES.appeal,
    shortName: INTAKE_FORM_NAMES_SHORT.appeal,
    category: 'decisionReview',
    formName: 'appeal'
  },
  HIGHER_LEVEL_REVIEW: {
    key: 'higher_level_review',
    name: INTAKE_FORM_NAMES.higher_level_review,
    shortName: INTAKE_FORM_NAMES_SHORT.higher_level_review,
    category: 'decisionReview',
    formName: 'higherLevelReview'
  },
  SUPPLEMENTAL_CLAIM: {
    key: 'supplemental_claim',
    name: INTAKE_FORM_NAMES.supplemental_claim,
    shortName: INTAKE_FORM_NAMES_SHORT.supplemental_claim,
    category: 'decisionReview',
    formName: 'supplementalClaim'
  },
  RAMP_REFILING: {
    key: 'ramp_refiling',
    name: INTAKE_FORM_NAMES.ramp_refiling,
    category: 'ramp',
    formName: 'rampRefiling'
  },
  RAMP_ELECTION: {
    key: 'ramp_election',
    name: INTAKE_FORM_NAMES.ramp_election,
    category: 'ramp',
    formName: 'rampElection'
  }
};

export const PAGE_PATHS = {
  BEGIN: '/',
  SEARCH: '/search',
  REVIEW: '/review_request',
  ADD_CLAIMANT: '/add_claimant',
  ADD_POWER_OF_ATTORNEY: '/add_power_of_attorney',
  FINISH: '/finish',
  ADD_ISSUES: '/add_issues',
  COMPLETED: '/completed',
  NOT_EDITABLE: '/not_editable',
  CANCEL_ISSUES: '/cancel',
  CONFIRMATION: '/confirmation',
  CLEARED_EPS: '/cleared_eps',
  OUTCODED: '/outcoded',
};

export const INTAKE_STATES = {
  NONE: 'NONE',
  STARTED: 'STARTED',
  REVIEWED: 'REVIEWED',
  COMPLETED: 'COMPLETED'
};

export const BOOLEAN_RADIO_OPTIONS = [
  { value: 'false',
    displayText: 'No' },
  { value: 'true',
    displayText: 'Yes' }
];

export const CORRECTION_TYPE_OPTIONS = [
  { value: 'control',
    displayText: 'Control' },
  { value: 'local_quality_error',
    displayText: 'Local Quality Error' },
  { value: 'national_quality_error',
    displayText: 'National Quality Error' }
];

export const BOOLEAN_RADIO_OPTIONS_DISABLED_FALSE = [
  { value: 'false',
    displayText: 'No',
    disabled: true },
  { value: 'true',
    displayText: 'Yes' }
];

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
  SET_RECEIPT_DATE_ERROR: 'SET_RECEIPT_DATE_ERROR',
  SET_VETERAN_IS_NOT_CLAIMANT: 'SET_VETERAN_IS_NOT_CLAIMANT',
  SET_CLAIMANT: 'SET_CLAIMANT',
  SET_PAYEE_CODE: 'SET_PAYEE_CODE',
  SET_LEGACY_OPT_IN_APPROVED: 'SET_LEGACY_OPT_IN_APPROVED',
  SET_APPEAL_DOCKET: 'SET_APPEAL_DOCKET',
  SET_DOCKET_TYPE: 'SET_DOCKET_TYPE',
  TOGGLE_CANCEL_MODAL: 'TOGGLE_CANCEL_MODAL',
  TOGGLE_ADDING_ISSUE: 'TOGGLE_ADDING_ISSUE',
  TOGGLE_ADD_ISSUES_MODAL: 'TOGGLE_ADD_ISSUES_MODAL',
  TOGGLE_NONRATING_REQUEST_ISSUE_MODAL: 'TOGGLE_NONRATING_REQUEST_ISSUE_MODAL',
  TOGGLE_UNIDENTIFIED_ISSUES_MODAL: 'TOGGLE_UNIDENTIFIED_ISSUES_MODAL',
  TOGGLE_UNTIMELY_EXEMPTION_MODAL: 'TOGGLE_UNTIMELY_EXEMPTION_MODAL',
  TOGGLE_ISSUE_REMOVE_MODAL: 'TOGGLE_ISSUE_REMOVE_MODAL',
  TOGGLE_CORRECTION_TYPE_MODAL: 'TOGGLE_CORRECTION_TYPE_MODAL',
  TOGGLE_LEGACY_OPT_IN_MODAL: 'TOGGLE_LEGACY_OPT_IN_MODAL',
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
  WITHDRAW_ISSUE: 'WITHDRAW_ISSUE',
  SET_ISSUE_WITHDRAWAL_DATE: 'SET_ISSUE_WITHDRAWAL_DATE',
  CORRECT_ISSUE: 'CORRECT_ISSUE',
  UNDO_CORRECTION: 'UNDO_CORRECTION',
  ADD_NONRATING_REQUEST_ISSUE: 'ADD_NONRATING_REQUEST_ISSUE',
  NEW_NONRATING_REQUEST_ISSUE: 'NEW_NONRATING_REQUEST_ISSUE',
  SET_ISSUE_CATEGORY: 'SET_ISSUE_CATEGORY',
  SET_ISSUE_DESCRIPTION: 'SET_ISSUE_DESCRIPTION',
  SET_ISSUE_DECISION_DATE: 'SET_ISSUE_DECISION_DATE',
  SET_ISSUE_BENEFIT_TYPE: 'SET_ISSUE_BENEFIT_TYPE',
  SET_HAS_INELIGIBLE_ISSUE: 'SET_HAS_INELIGIBLE_ISSUE',
  CONFIRM_INELIGIBLE_FORM: 'CONFIRM_INELIGIBLE_FORM',
  CONFIRM_OUTSIDE_CASEFLOW_STEPS: 'CONFIRM_OUTSIDE_CASEFLOW_STEPS',
  COMPLETE_INTAKE_STEPS_NOT_CONFIRMED: 'COMPLETE_INTAKE_STEPS_NOT_CONFIRMED',
  PROCESS_FINISH_ERROR: 'PROCESS_FINISH_ERROR',
  NO_ISSUES_SELECTED_ERROR: 'NO_ISSUES_SELECTED_ERROR',
  SET_EDIT_CONTENTION_TEXT: 'SET_EDIT_CONTENTION_TEXT'
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

export const REVIEW_DATA_FIELDS = {
  appeal: {
    docket_type: { key: 'docketType', required: true },
    receipt_date: { key: 'receiptDate', required: true },
    claimant: { key: 'claimant' },
    unlisted_claimant: { key: 'unlistedClaimant' },
    poa: { key: 'poa' },
    claimant_notes: { key: 'claimantNotes' },
    claimant_type: { key: 'claimantType', required: true },
    payee_code: { key: 'payeeCode' },
    legacy_opt_in_approved: { key: 'legacyOptInApproved', required: true },
  },
  supplementalClaim: {
    benefit_type: { key: 'benefitType', required: true },
    receipt_date: { key: 'receiptDate', required: true },
    claimant: { key: 'claimant' },
    claimant_type: { key: 'claimantType', required: true },
    payee_code: { key: 'payeeCode' },
    legacy_opt_in_approved: { key: 'legacyOptInApproved', required: true },
  },
  higherLevelReview: {
    informal_conference: { key: 'informalConference', required: true },
    same_office: { key: 'sameOffice', required: true },
    benefit_type: { key: 'benefitType', required: true },
    receipt_date: { key: 'receiptDate', required: true },
    claimant: { key: 'claimant' },
    claimant_type: { key: 'claimantType', required: true },
    payee_code: { key: 'payeeCode' },
    legacy_opt_in_approved: { key: 'legacyOptInApproved', required: true },
  },
};

export const GENERIC_FORM_ERRORS = {
  blank: 'Please select an option.'
}

export const RECEIPT_DATE_ERRORS = {
  invalid: 'Please enter a valid receipt date.',
  in_future: 'Receipt date cannot be in the future.'
}

export const CLAIMANT_ERRORS = {
  blank: 'Please select an option.',
  claimant_address_required: "Please supply the claimant's address in VBMS.",
  claimant_address_invalid: "Please update the claimant's address in VBMS to be valid.",
  claimant_city_invalid: "Please update the claimant's city in VBMS to be valid."
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

export const VBMS_BENEFIT_TYPES = ['compensation', 'pension', 'fiduciary'];
