import { css } from 'glamor';

export const COLORS = {
  QUEUE_LOGO_PRIMARY: '#11598D',
  QUEUE_LOGO_OVERLAP: '#0E456C',
  QUEUE_LOGO_BACKGROUND: '#D6D7D9',
  // $color-secondary-dark in uswds/core/_variables.scss
  ERROR: '#CD2026'
};

export const ACTIONS = {
  RECEIVE_QUEUE_DETAILS: 'RECEIVE_QUEUE_DETAILS',
  RECEIVE_JUDGE_DETAILS: 'RECEIVE_JUDGE_DETAILS',
  SET_LOADED_QUEUE_ID: 'SET_LOADED_QUEUE_ID',
  SET_APPEAL_DOC_COUNT: 'SET_APPEAL_DOC_COUNT',
  LOAD_APPEAL_DOC_COUNT_FAILURE: 'LOAD_APPEAL_DOC_COUNT_FAILURE',
  SET_REVIEW_ACTION_TYPE: 'SET_REVIEW_ACTION_TYPE',
  SET_DECISION_OPTIONS: 'SET_DECISION_OPTIONS',
  RESET_DECISION_OPTIONS: 'RESET_DECISION_OPTIONS',
  START_EDITING_APPEAL: 'START_EDITING_APPEAL',
  CANCEL_EDITING_APPEAL: 'CANCEL_EDITING_APPEAL',
  START_EDITING_APPEAL_ISSUE: 'START_EDITING_APPEAL_ISSUE',
  CANCEL_EDITING_APPEAL_ISSUE: 'CANCEL_EDITING_APPEAL_ISSUE',
  SAVE_EDITED_APPEAL_ISSUE: 'SAVE_EDITED_APPEAL_ISSUE',
  UPDATE_APPEAL_ISSUE: 'UPDATE_APPEAL_ISSUE',
  SET_SELECTING_JUDGE: 'SET_SELECTING_JUDGE',
  PUSH_BREADCRUMB: 'PUSH_BREADCRUMB',
  RESET_BREADCRUMBS: 'RESET_BREADCRUMBS',
  HIGHLIGHT_INVALID_FORM_ITEMS: 'HIGHLIGHT_INVALID_FORM_ITEMS'
};

// 'red' isn't contrasty enough w/white; it raises Sniffybara::PageNotAccessibleError when testing
export const redText = css({ color: '#E60000' });
export const boldText = css({ fontWeight: 'bold' });
export const fullWidth = css({ width: '100%' });

export const CATEGORIES = {
  QUEUE_TABLE: 'Queue Table',
  QUEUE_TASK: 'Queue Task'
};

export const TASK_ACTIONS = {
  VIEW_APPELLANT_INFO: 'view-appellant-info',
  VIEW_APPEAL_INFO: 'view-appeal-info',
  QUEUE_TO_READER: 'queue-to-reader'
};

export const ERROR_FIELD_REQUIRED = 'This field is required';

export const ISSUE_PROGRAMS = {
  '01': 'VBA Burial',
  '02': 'Compensation',
  '03': 'Education',
  '04': 'Insurance',
  '05': 'Loan Guaranty',
  '06': 'Medical',
  '07': 'Pension',
  '08': 'VRE',
  '09': 'Other',
  '10': 'BVA',
  '11': 'NCA Burial',
  '12': 'Fiduciary',
}