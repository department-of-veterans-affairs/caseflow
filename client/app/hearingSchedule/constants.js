export const ACTIONS = {
  RECEIVE_PAST_UPLOADS: 'RECEIVE_PAST_UPLOADS',
  RECEIVE_SCHEDULE_PERIOD: 'RECEIVE_SCHEDULE_PERIOD',
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
  UNSET_SUCCESS_MESSAGE: 'UNSET_SUCCESS_MESSAGE'
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
