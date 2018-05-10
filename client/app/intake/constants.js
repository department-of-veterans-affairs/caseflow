export const PAGE_PATHS = {
  BEGIN: '/',
  SEARCH: '/search',
  REVIEW: '/review-request',
  FINISH: '/finish',
  COMPLETED: '/completed'
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
  SET_RECEIPT_DATE: 'SET_RECEIPT_DATE',
  SET_APPEAL_DOCKET: 'SET_APPEAL_DOCKET',
  TOGGLE_CANCEL_MODAL: 'TOGGLE_CANCEL_MODAL',
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
  SET_HAS_INELIGIBLE_ISSUE: 'SET_HAS_INELIGIBLE_ISSUE',
  CONFIRM_INELIGIBLE_FORM: 'CONFIRM_INELIGIBLE_FORM',
  CONFIRM_OUTSIDE_CASEFLOW_STEPS: 'CONFIRM_OUTSIDE_CASEFLOW_STEPS',
  COMPLETE_INTAKE_STEPS_NOT_CONFIRMED: 'COMPLETE_INTAKE_STEPS_NOT_CONFIRMED',
  PROCESS_FINISH_ERROR: 'PROCESS_FINISH_ERROR',
  NO_ISSUES_SELECTED_ERROR: 'NO_ISSUES_SELECTED_ERROR'
};

export const REQUEST_STATE = {
  NOT_STARTED: 'NOT_STARTED',
  IN_PROGRESS: 'IN_PROGRESS',
  SUCCEEDED: 'SUCCEEDED',
  FAILED: 'FAILED'
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
    name: 'Higher Level Review'
  },
  HIGHER_LEVEL_REVIEW_WITH_HEARING: {
    key: 'higher_level_review_with_hearing',
    name: 'Higher Level Review with Informal Conference'
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

export const FORM_TYPES = {
  RAMP_ELECTION: {
    key: 'ramp_election',
    name: 'RAMP Opt-In Election Form',
    category: 'ramp'
  },
  RAMP_REFILING: {
    key: 'ramp_refiling',
    name: 'RAMP Selection (VA Form 21-4138)',
    category: 'ramp'
  },
  HIGHER_LEVEL_REVIEW: {
    key: 'higher_level_review',
    name: 'Request for Higher-Level Review (VA Form 20-0988)',
    category: 'ama'
  },
  SUPPLEMENTAL_CLAIM: {
    key: 'supplemental_claim',
    name: 'Supplemental Claim (VA Form 21-526b)',
    category: 'ama'
  },
  NOTICE_OF_DISAGREEMENT: {
    key: 'notice_of_disagreement',
    name: 'Notice of Disagreement (VA Form 10182)',
    category: 'ama'
  }
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
