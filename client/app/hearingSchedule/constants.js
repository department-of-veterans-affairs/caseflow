export const ACTIONS = {
  RECEIVE_PAST_UPLOADS: 'RECEIVE_PAST_UPLOADS',
  RECEIVE_SCHEDULE_PERIOD: 'RECEIVE_SCHEDULE_PERIOD',
  FILE_TYPE_CHANGE: 'FILE_TYPE_CHANGE',
  RECEIVE_HEARING_SCHEDULE: 'RECEIVE_HEARING_SCHEDULE',
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
  'ValidationError::MissingStartDateEndDateFile': 'Please upload a file and enter a start date and an end date.',
  'ValidationError::EndDateTooEarly': 'Please enter an end date that is after the start date.',
  'SchedulePeriod::OverlappingSchedulePeriods': 'You have already uploaded a file for these dates. Please check your ' +
    'file to make sure you have entered the correct dates.',
  'HearingSchedule::ValidateRoSpreadsheet::RoDatesNotUnique': 'You have listed duplicate non-availability dates for ' +
    'an RO. Please update spreadsheet and try again.',
  'HearingSchedule::ValidateRoSpreadsheet::RoDatesNotInRange': 'The ro non-availability spreadsheet contains dates ' +
    'outside the range you selected. Please update these dates and try again.',
  'HearingSchedule::ValidateRoSpreadsheet::RoDatesNotCorrectFormat': 'All dates must be in the following format : ' +
    'mm/dd/yyyy. Please check the RO non-availability sheet to make sure all dates match this format.',
  'HearingSchedule::ValidateRoSpreadsheet::RoTemplateNotFollowed': 'We have found column names that vary from the ' +
    'template. Please check the RO non-availability sheet for any additional or different columns and upload the ' +
    'corrected file again.',
  'HearingSchedule::ValidateRoSpreadsheet::RoListedIncorrectly': 'The ro non-availability spreadsheet lists ' +
    'different ROs than we have in our system. Please ensure every Regional Office has a row and upload the ' +
    'corrected file.',
  'HearingSchedule::ValidateRoSpreadsheet::CoDatesNotUnique': 'The central office non-availability spreadsheet ' +
    'contains dates outside the range you selected. Please update these dates and try again.',
  'HearingSchedule::ValidateRoSpreadsheet::CoDatesNotInRange': 'The central office non-availability spreadsheet ' +
    'contains dates outside the range you selected. Please update these dates and try again.',
  'HearingSchedule::ValidateRoSpreadsheet::CoDatesNotCorrectFormat': 'All dates must be in the following format : ' +
    'mm/dd/yyyy. Please check the CO non-availability sheet to make sure all dates match this format.',
  'HearingSchedule::ValidateRoSpreadsheet::CoTemplateNotFollowed': 'We have found column names that vary from the ' +
    'template. Please check the CO non-availability sheet for any additional or different columns and upload the ' +
    'corrected file again.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationNotCorrectFormat': 'The central office non-availability ' +
    'spreadsheet contains dates outside the range you selected. Please update these dates and try again.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationRoListedIncorrectly': 'The allocation spreadsheet lists ' +
    'different ROs than we have in our system. Please ensure every Regional Office has a row and upload the ' +
    'corrected file.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationDuplicateRo': 'The allocation spreadsheet lists the same RO ' +
    'twice. Please update the spreadsheet and try again.',
  'HearingSchedule::ValidateRoSpreadsheet::AllocationTemplateNotFollowed': 'We have found column names that vary ' +
    'from the template. Please check the allocation sheet for any additional or different columns and upload the ' +
    'corrected file again.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotCorrectFormat': 'All dates must be in the following ' +
    'format: mm/dd/yyyy. Please check the judge non-availability sheet to make sure all dates match this format.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeTemplateNotFollowed': 'We have found column names that vary from ' +
    'the template. Please check the spreadsheet for any additional or different columns and upload the corrected ' +
    'file again.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotUnique': 'You have listed duplicate non-availability ' +
    'dates for a judge. Please update the spreadsheet and try again.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeDatesNotInRange': 'The judge non-availability spreadsheet ' +
    'contains dates outside the range you selected. Please update these dates and try again.',
  'HearingSchedule::ValidateJudgeSpreadsheet::JudgeNotInDatabase': 'A judge listed in the spreadsheet is not in our ' +
    'database. Please check the CSS IDs and try again.',
  'ValidationError::UnspecifiedError': 'Something went wrong while uploading the spreadsheet. Please check the data ' +
    'and try again.'
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
