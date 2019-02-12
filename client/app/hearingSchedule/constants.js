export const ACTIONS = {
  RECEIVE_PAST_UPLOADS: 'RECEIVE_PAST_UPLOADS',
  RECEIVE_SCHEDULE_PERIOD: 'RECEIVE_SCHEDULE_PERIOD',
  RECEIVE_REGIONAL_OFFICES: 'RECEIVE_REGIONAL_OFFICES',
  RECEIVE_DAILY_DOCKET: 'RECEIVE_DAILY_DOCKET',
  RECEIVE_SAVED_HEARING: 'RECEIVE_SAVED_HEARING',
  RESET_SAVE_SUCCESSFUL: 'RESET_SAVE_SUCCESSFUL',
  CANCEL_HEARING_UPDATE: 'CANCEL_HEARING_UPDATE',
  RECEIVE_HEARING_DAY_OPTIONS: 'RECEIVE_HEARING_DAY_OPTIONS',
  RECEIVE_UPCOMING_HEARING_DAYS: 'RECEIVE_UPCOMING_HEARING_DAYS',
  REGIONAL_OFFICE_CHANGE: 'REGIONAL_OFFICE_CHANGE',
  RECEIVE_APPEALS_READY_FOR_HEARING: 'RECEIVE_APPEALS_READY_FOR_HEARING',
  HEARING_NOTES_UPDATE: 'HEARING_NOTES_UPDATE',
  TRANSCRIPT_REQUESTED_UPDATE: 'TRANSCRIPT_REQUESTED_UPDATE',
  HEARING_DISPOSITION_UPDATE: 'HEARING_DISPOSITION_UPDATE',
  HEARING_DATE_UPDATE: 'HEARING_DATE_UPDATE',
  HEARING_TIME_UPDATE: 'HEARING_TIME_UPDATE',
  HEARING_OPTIONAL_TIME: 'HEARING_OPTIONAL_TIME',
  HEARING_LOCATION_UPDATE: 'HEARING_LOCATION_UPDATE',
  HEARING_REGIONAL_OFFICE_UPDATE: 'HEARING_REGIONAL_OFFICE_UPDATE',
  SELECTED_HEARING_DAY_CHANGE: 'SELECTED_HEARING_DAY_CHANGE',
  FILE_TYPE_CHANGE: 'FILE_TYPE_CHANGE',
  RECEIVE_HEARING_SCHEDULE: 'RECEIVE_HEARING_SCHEDULE',
  SCHEDULE_PERIOD_ERROR: 'SCHEDULE_PERIOD_ERROR',
  REMOVE_SCHEDULE_PERIOD_ERROR: 'REMOVE_SCHEDULE_PERIOD_ERROR',
  SET_VACOLS_UPLOAD: 'SET_VACOLS_UPLOAD',
  RO_CO_START_DATE_CHANGE: 'RO_CO_START_DATE_CHANGE',
  RO_CO_END_DATE_CHANGE: 'RO_CO_END_DATE_CHANGE',
  RO_CO_FILE_UPLOAD: 'RO_CO_FILE_UPLOAD',
  JUDGE_START_DATE_CHANGE: 'JUDGE_START_DATE_CHANGE',
  JUDGE_END_DATE_CHANGE: 'JUDGE_END_DATE_CHANGE',
  JUDGE_FILE_UPLOAD: 'JUDGE_FILE_UPLOAD',
  UPDATE_UPLOAD_FORM_ERRORS: 'UPDATE_UPLOAD_FORM_ERRORS',
  UPDATE_RO_CO_UPLOAD_FORM_ERRORS: 'UPDATE_RO_CO_UPLOAD_FORM_ERRORS',
  UPDATE_JUDGE_UPLOAD_FORM_ERRORS: 'UPDATE_JUDGE_UPLOAD_FORM_ERRORS',
  UNSET_UPLOAD_ERRORS: 'UNSET_UPLOAD_ERRORS',
  TOGGLE_UPLOAD_CONTINUE_LOADING: 'TOGGLE_UPLOAD_CONTINUE_LOADING',
  VIEW_START_DATE_CHANGE: 'VIEW_START_DATE_CHANGE',
  VIEW_END_DATE_CHANGE: 'VIEW_END_DATE_CHANGE',
  CLICK_CONFIRM_ASSIGNMENTS: 'CLICK_CONFIRM_ASSIGNMENTS',
  CLICK_CLOSE_MODAL: 'CLICK_CLOSE_MODAL',
  CONFIRM_ASSIGNMENTS_UPLOAD: 'CONFIRM_ASSIGNMENTS_UPLOAD',
  UNSET_SUCCESS_MESSAGE: 'UNSET_SUCCESS_MESSAGE',
  TOGGLE_TYPE_FILTER_DROPDOWN: 'TOGGLE_TYPE_FILTER_DROPDOWN',
  TOGGLE_LOCATION_FILTER_DROPDOWN: 'TOGGLE_LOCATION_FILTER_DROPDOWN',
  TOGGLE_VLJ_FILTER_DROPDOWN: 'TOGGLE_VLJ_FILTER_DROPDOWN',
  SELECT_REQUEST_TYPE: 'SELECT_REQUEST_TYPE',
  SELECT_VLJ: 'SELECT_VLJ',
  SELECT_COORDINATOR: 'SELECT_COORDINATOR',
  SELECT_HEARING_ROOM: 'SELECT_HEARING_ROOM',
  SET_NOTES: 'SET_NOTES',
  RECEIVE_JUDGES: 'RECEIVE_JUDGES',
  RECEIVE_COORDINATORS: 'RECEIVE_COORDINATORS',
  HEARING_DAY_MODIFIED: 'HEARING_DAY_MODIFIED',
  ON_CLICK_REMOVE_HEARING_DAY: 'ON_CLICK_REMOVE_HEARING_DAY',
  CANCEL_REMOVE_HEARING_DAY: 'CANCEL_REMOVE_HEARING_DAY',
  SUCCESSFUL_HEARING_DAY_DELETE: 'SUCCESSFUL_HEARING_DAY_DELETE',
  RESET_DELETE_SUCCESSFUL: 'RESET_DELETE_SUCCESSFUL',
  ASSIGN_HEARING_ROOM: 'ASSIGN_HEARING_ROOM',
  DISPLAY_LOCK_MODAL: 'DISPLAY_LOCK_MODAL',
  CANCEL_DISPLAY_LOCK_MODAL: 'CANCEL_DISPLAY_LOCK_MODAL',
  UPDATE_LOCK: 'UPDATE_LOCK',
  RESET_LOCK_SUCCESS_MESSAGE: 'RESET_LOCK_SUCCESS_MESSAGE',
  HANDLE_DAILY_DOCKET_SERVER_ERROR: 'HANDLE_DAILY_DOCKET_SERVER_ERROR',
  RESET_DAILY_DOCKET_AFTER_SERVER_ERROR: 'RESET_DAILY_DOCKET_AFTER_SERVER_ERROR',
  HANDLE_LOCK_HEARING_SERVER_ERROR: 'HANDLE_LOCK_HEARING_SERVER_ERROR',
  RESET_LOCK_HEARING_SERVER_ERROR: 'RESET_LOCK_HEARING_SERVER_ERROR',
  INVALID_FORM: 'INVALID_FORM'
};

export const ERROR_MAPPINGS = {
  'ValidationError::MissingStartDateEndDateFile': 'The start date, end date, or file are missing.',
  'ValidationError::EndDateTooEarly': 'The end date is before the start date.',
  'SchedulePeriod::OverlappingSchedulePeriods': 'You have already uploaded a file for these dates.',
  'HearingSchedule::ValidateRoSpreadsheet::RoDatesNotUnique': 'The RO non-availability spreadsheet contains ' +
    'duplicate dates for an RO.',
  'HearingSchedule::ValidateRoSpreadsheet::RoDatesNotInRange': 'The RO non-availability spreadsheet contains dates ' +
    'outside the range you selected.',
  'HearingSchedule::ValidateRoSpreadsheet::RoDatesNotCorrectFormat': 'The RO non-availability spreadsheet contains ' +
    'dates that are not in this format: mm/dd/yyyy.',
  'HearingSchedule::ValidateRoSpreadsheet::RoTemplateNotFollowed': 'The RO non-availability spreadsheet does not ' +
    'follow the template.',
  'HearingSchedule::ValidateRoSpreadsheet::RoListedIncorrectly': 'The RO non-availability spreadsheet contains ' +
    'different ROs than we have in our system.',
  'HearingSchedule::ValidateRoSpreadsheet::CoDatesNotUnique': 'The central office non-availability spreadsheet ' +
    'contains duplicate dates.',
  'HearingSchedule::ValidateRoSpreadsheet::CoDatesNotInRange': 'The central office non-availability spreadsheet ' +
    'contains dates outside the range you selected.',
  'HearingSchedule::ValidateRoSpreadsheet::CoDatesNotCorrectFormat': 'The central office non-availability ' +
    'spreadsheet contains dates that are not in this format: mm/dd/yyyy.',
  'HearingSchedule::ValidateRoSpreadsheet::CoTemplateNotFollowed': 'The central office non-availability spreadsheet ' +
    'does not follow the template.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationNotCorrectFormat': 'The allocation spreadsheet has the ' +
    'incorrect data type for an allocation.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationRoListedIncorrectly': 'The allocation spreadsheet contains ' +
    'different ROs than we have in our system.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationDuplicateRo': 'The allocation spreadsheet contains the same RO ' +
    'twice.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationTemplateNotFollowed': 'The allocation spreadsheet does not ' +
    'follow the template.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotCorrectFormat': 'The judge non-availability ' +
    'spreadsheet contains dates that are not in this format: mm/dd/yyyy.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeTemplateNotFollowed': 'The judge non-availability spreadsheet ' +
    'does not follow the template.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotUnique': 'The judge non-availability spreadsheet contains ' +
    'duplicate dates for a judge.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotInRange': 'The judge non-availability spreadsheet ' +
    'contains dates outside the range you selected.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeNotInDatabase': 'The judge non-availability spreadsheet contains ' +
    'a judge not in our database.',
  'ValidationError::UnspecifiedError': 'The spreadsheet is invalid.'
};

export const SPREADSHEET_TYPES = {
  RoSchedulePeriod: {
    value: 'RoSchedulePeriod',
    shortDisplay: 'RO/CO',
    display: 'RO/CO hearings',
    template: '/ROAssignmentTemplate.xlsx'
  },
  JudgeSchedulePeriod: {
    value: 'JudgeSchedulePeriod',
    shortDisplay: 'Judge',
    display: 'Judge non-availability',
    template: '/JudgeAssignmentTemplate.xlsx'
  }
};
