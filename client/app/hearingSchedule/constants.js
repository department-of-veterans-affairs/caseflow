export const ACTIONS = {
  RECEIVE_PAST_UPLOADS: 'RECEIVE_PAST_UPLOADS',
  FILE_TYPE_CHANGE: 'FILE_TYPE_CHANGE',
  RECEIVE_HEARING_SCHEDULE: 'RECEIVE_HEARING_SCHEDULE',
  RO_CO_START_DATE_CHANGE: 'RO_CO_START_DATE_CHANGE',
  RO_CO_END_DATE_CHANGE: 'RO_CO_END_DATE_CHANGE',
  RO_CO_FILE_UPLOAD: 'RO_CO_FILE_UPLOAD',
  JUDGE_START_DATE_CHANGE: 'JUDGE_START_DATE_CHANGE',
  JUDGE_END_DATE_CHANGE: 'JUDGE_END_DATE_CHANGE',
  JUDGE_FILE_UPLOAD: 'JUDGE_FILE_UPLOAD',
  TOGGLE_UPLOAD_CONTINUE_LOADING: 'TOGGLE_UPLOAD_CONTINUE_LOADING',
  VIEW_START_DATE_CHANGE: 'VIEW_START_DATE_CHANGE',
  VIEW_END_DATE_CHANGE: 'VIEW_END_DATE_CHANGE'
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
