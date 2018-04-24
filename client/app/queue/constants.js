/* eslint-disable max-lines */
import { css } from 'glamor';
import _ from 'lodash';
import VACOLS_DISPOSITIONS_BY_ID from '../../../constants/VACOLS_DISPOSITIONS_BY_ID.json';
import REMAND_REASONS_BY_ID from '../../../constants/ACTIVE_REMAND_REASONS_BY_ID.json';

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
  EDIT_APPEAL: 'EDIT_APPEAL',
  DELETE_APPEAL: 'DELETE_APPEAL',
  STAGE_APPEAL: 'STAGE_APPEAL',
  EDIT_STAGED_APPEAL: 'EDIT_STAGED_APPEAL',
  CHECKOUT_STAGED_APPEAL: 'CHECKOUT_STAGED_APPEAL',
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
  CASE_DETAIL: 'Queue Appeal',
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

export const CASE_DISPOSITION_ID_BY_DESCRIPTION = Object.assign({},
  ...Object.keys(VACOLS_DISPOSITIONS_BY_ID).map((dispositionId) => ({
    [VACOLS_DISPOSITIONS_BY_ID[dispositionId].toLowerCase().replace(/ /g, '_')]: dispositionId
  }))
);

export const REMAND_REASONS = Object.assign({},
  ...Object.keys(REMAND_REASONS_BY_ID).map((reasonType) => ({
    [reasonType]: _.map(REMAND_REASONS_BY_ID[reasonType], (label, reasonId) => ({
      id: reasonId,
      label
    }))
  }))
);
