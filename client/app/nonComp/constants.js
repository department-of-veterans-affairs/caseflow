export const DISPOSITION_OPTIONS = ['Granted', 'Denied', 'DTA Error', 'Dismissed', 'Withdrawn'];

export const ACTIONS = {
  TASK_UPDATE_DECISION_ISSUES_START: 'TASK_UPDATE_DECISION_ISSUES_START',
  TASK_UPDATE_DECISION_ISSUES_SUCCEED: 'TASK_UPDATE_DECISION_ISSUES_SUCCEED',
  TASK_UPDATE_DECISION_ISSUES_FAIL: 'TASK_UPDATE_DECISION_ISSUES_FAIL',
  TASK_DEFAULT_PAGE: 'TASK_DEFAULT_PAGE',
  STARTED_LOADING_POWER_OF_ATTORNEY_VALUE: 'STARTED_LOADING_POWER_OF_ATTORNEY_VALUE',
  RECEIVED_POWER_OF_ATTORNEY: 'RECEIVED_POWER_OF_ATTORNEY',
  ERROR_ON_RECEIVE_POWER_OF_ATTORNEY_VALUE: 'ERROR_ON_RECEIVE_POWER_OF_ATTORNEY_VALUE',
  SET_POA_REFRESH_ALERT: 'SET_POA_REFRESH_ALERT',
  FETCH_TASK_FILTER_DETAILS_START: 'FETCH_TASK_FILTER_DETAILS_START',
  FETCH_TASK_FILTER_DETAILS_SUCCEED: 'FETCH_TASK_FILTER_DETAILS_SUCCEED',
  FETCH_TASK_FILTER_DETAILS_FAIL: 'FETCH_TASK_FILTER_DETAILS_FAIL',
  FETCH_BUSINESSLINE_INFO_START: 'FETCH_BUSINESSLINE_INFO_START',
  FETCH_BUSINESSLINE_INFO_SUCCEED: 'FETCH_BUSINESSLINE_INFO_SUCCEED',
  FETCH_BUSINESSLINE_INFO_FAIL: 'FETCH_BUSINESSLINE_INFO_FAIL'
};

export const DECISION_ISSUE_UPDATE_STATUS = {
  IN_PROGRESS: 'IN_PROGRESS',
  SUCCEED: 'SUCCEED',
  FAIL: 'FAIL'
};

export const BOA_ADDRESS = '425 I St NW, Washington DC, 20001';
export const GENERATE_REPORT_ERROR =
  'An error occurred, please try again. If the problem persists, submit a help desk ticket.';

export const RESET_FORM_VALUES = {
  reportType: '',
  conditions: [],
  timing: {
    range: null,
    startDate: '',
    endDate: '',
  },
  radioEventAction: 'all_events_action',
  radioStatus: 'all_statuses',
  radioStatusReportType: 'last_action_taken',
  specificStatus: {
    incomplete: false,
    in_progress: false,
    pending: false,
    completed: false,
    cancelled: false
  },
  specificEventType: {
    claim_created: false,
    claim_closed: false,
    claim_status_incomplete: false,
    claim_status_pending: false,
    claim_status_inprogress: false,
    added_decision_date: false,
    added_issue: false,
    added_issue_no_decision_date: false,
    removed_issue: false,
    withdrew_issue: false,
    completed_disposition: false,
    requested_issue_modification: false,
    requested_issue_addition: false,
    requested_issue_removal: false,
    requested_issue_withdrawal: false,
    approval_of_request: false,
    rejection_of_request: false,
    cancellation_of_request: false,
    edit_of_request: false,
  }
};
