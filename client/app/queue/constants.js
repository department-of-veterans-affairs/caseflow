/* eslint-disable max-lines */
import { css } from 'glamor';
import VACOLS_DISPOSITIONS_BY_ID from '../../../constants/VACOLS_DISPOSITIONS_BY_ID.json';

export REMAND_REASONS from '../../../constants/REMAND_REASONS.json';
// https://git.io/vxBtN
export ISSUE_INFO from '../../../constants/ISSUE_LEVELS.json';

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
  EDIT_APPEAL: 'EDIT_APPEAL',
  DELETE_APPEAL: 'DELETE_APPEAL',
  CANCEL_EDITING_APPEAL: 'CANCEL_EDITING_APPEAL',
  START_EDITING_APPEAL_ISSUE: 'START_EDITING_APPEAL_ISSUE',
  CANCEL_EDITING_APPEAL_ISSUE: 'CANCEL_EDITING_APPEAL_ISSUE',
  SAVE_EDITED_APPEAL_ISSUE: 'SAVE_EDITED_APPEAL_ISSUE',
  UPDATE_EDITING_APPEAL_ISSUE: 'UPDATE_EDITING_APPEAL_ISSUE',
  DELETE_EDITING_APPEAL_ISSUE: 'DELETE_EDITING_APPEAL_ISSUE'
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

export const DECISION_TYPES = {
  OMO_REQUEST: 'OMORequest',
  DRAFT_DECISION: 'DraftDecision'
};

export const SEARCH_ERROR_FOR = {
  INVALID_VETERAN_ID: 'INVALID_VETERAN_ID',
  NO_APPEALS: 'NO_APPEALS',
  UNKNOWN_SERVER_ERROR: 'UNKNOWN_SERVER_ERROR'
};

export const CASE_DISPOSITION_ID_BY_DESCRIPTION = Object.assign(
  {}, ...Object.keys(VACOLS_DISPOSITIONS_BY_ID).map(
    (id) => ({ [VACOLS_DISPOSITIONS_BY_ID[id].toLowerCase().replace(/ /g, '_')]: id })
  )
);
