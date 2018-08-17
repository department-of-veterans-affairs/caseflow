/* eslint-disable max-lines */
import { css } from 'glamor';
import _ from 'lodash';
import VACOLS_DISPOSITIONS_BY_ID from '../../constants/VACOLS_DISPOSITIONS_BY_ID.json';
import REMAND_REASONS_BY_ID from '../../constants/ACTIVE_REMAND_REASONS_BY_ID.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import StringUtil from '../util/StringUtil';
import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';
import CO_LOCATED_ACTIONS from '../../constants/CO_LOCATED_ACTIONS.json';
import VACOLS_COLUMN_MAX_LENGTHS from '../../constants/VACOLS_COLUMN_MAX_LENGTHS.json';

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
  RECEIVE_NEW_FILES: 'RECEIVE_NEW_FILES',
  ERROR_ON_RECEIVE_NEW_FILES: 'ERROR_ON_RECEIVE_NEW_FILES',
  SET_LOADED_QUEUE_ID: 'SET_LOADED_QUEUE_ID',
  SET_APPEAL_DOC_COUNT: 'SET_APPEAL_DOC_COUNT',
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
  DELETE_EDITING_APPEAL_ISSUE: 'DELETE_EDITING_APPEAL_ISSUE',
  SET_ATTORNEYS_OF_JUDGE: 'SET_ATTORNEYS_OF_JUDGE',
  SET_TASKS_AND_APPEALS_OF_ATTORNEY: 'SET_TASKS_AND_APPEALS_OF_ATTORNEY',
  REQUEST_TASKS_AND_APPEALS_OF_ATTORNEY: 'REQUEST_TASKS_AND_APPEALS_OF_ATTORNEY',
  ERROR_TASKS_AND_APPEALS_OF_ATTORNEY: 'ERROR_TASKS_AND_APPEALS_OF_ATTORNEY',
  SET_SELECTION_OF_TASK_OF_USER: 'SET_SELECTION_OF_TASK_OF_USER',
  SET_SELECTED_ASSIGNEE_OF_USER: 'SET_SELECTED_ASSIGNEE_OF_USER',
  START_ASSIGN_TASKS_TO_USER: 'START_ASSIGN_TASKS_TO_USER',
  RECEIVE_ALL_ATTORNEYS: 'RECEIVE_ALL_ATTORNEYS',
  ERROR_LOADING_ATTORNEYS: 'ERROR_LOADING_ATTORNEYS',
  RECEIVE_TASKS: 'RECEIVE_TASKS',
  RECEIVE_APPEAL_DETAILS: 'RECEIVE_APPEAL_DETAILS',
  SET_TASK_ASSIGNMENT: 'SET_TASK_ASSIGNMENT'
};

// 'red' isn't contrasty enough w/white; it raises Sniffybara::PageNotAccessibleError when testing
export const redText = css({ color: '#E60000' });
export const boldText = css({ fontWeight: 'bold' });
export const fullWidth = css({ width: '100%' });
export const dropdownStyling = css({ minHeight: 0 });
export const disabledLinkStyle = css({ color: COMMON_COLORS.GREY_MEDIUM });
export const subHeadTextStyle = css(disabledLinkStyle, {
  fontSize: 'small'
});
export const marginTop = (margin) => css({ marginTop: `${margin}rem` });
export const marginBottom = (margin) => css({ marginBottom: `${margin}rem` });
export const marginLeft = (margin) => css({ marginLeft: `${margin}rem` });
export const marginRight = (margin) => css({ marginRight: `${margin}rem` });

export const paddingLeft = (padding) => css({ paddingLeft: `${padding}rem` });

export const CATEGORIES = {
  CASE_DETAIL: 'Appeal Details',
  QUEUE_TABLE: 'Queue Table',
  QUEUE_TASK: 'Queue Task',
  EVALUATE_DECISION: 'Evaluate Decision'
};

export const TASK_ACTIONS = {
  VIEW_APPELLANT_INFO: 'view-appellant-info',
  VIEW_APPEAL_INFO: 'view-appeal-info',
  QUEUE_TO_READER: 'queue-to-reader'
};

export const COLOCATED_ACTIONS = [{
  // label: COPY.COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM,
  // value: CO_LOCATED_ACTIONS.SEND_TO_TEAM
// }, {
  label: COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY,
  value: CO_LOCATED_ACTIONS.SEND_BACK_TO_ATTORNEY
}];

export const JUDGE_DECISION_OPTIONS = {
  DRAFT_DECISION: {
    label: COPY.JUDGE_CHECKOUT_DISPATCH_LABEL,
    value: DECISION_TYPES.DISPATCH
  },
  OMO_REQUEST: {
    label: COPY.JUDGE_CHECKOUT_OMO_LABEL,
    value: DECISION_TYPES.OMO_REQUEST
  }
};

export const DRAFT_DECISION_OPTIONS = [{
  label: COPY.ATTORNEY_CHECKOUT_DRAFT_DECISION_LABEL,
  value: DECISION_TYPES.DRAFT_DECISION
}, {
  label: COPY.ATTORNEY_CHECKOUT_OMO_LABEL,
  value: DECISION_TYPES.OMO_REQUEST
}];

export const OMO_ATTORNEY_CASE_REVIEW_WORK_PRODUCT_TYPES = [{
  displayText: COPY.ATTORNEY_CHECKOUT_OMO_CASE_REVIEW_WORK_PRODUCT_VHA,
  value: COPY.ATTORNEY_CHECKOUT_OMO_CASE_REVIEW_WORK_PRODUCT_VHA
}, {
  displayText: COPY.ATTORNEY_CHECKOUT_OMO_CASE_REVIEW_WORK_PRODUCT_IME,
  value: COPY.ATTORNEY_CHECKOUT_OMO_CASE_REVIEW_WORK_PRODUCT_IME
}];

export const SEARCH_ERROR_FOR = {
  EMPTY_SEARCH_TERM: 'EMPTY_SEARCH_TERM',
  INVALID_VETERAN_ID: 'INVALID_VETERAN_ID',
  NO_APPEALS: 'NO_APPEALS',
  UNKNOWN_SERVER_ERROR: 'UNKNOWN_SERVER_ERROR'
};

export const REMAND_REASONS = Object.assign({},
  ...Object.keys(REMAND_REASONS_BY_ID).map((reasonType) => ({
    [reasonType]: _.map(REMAND_REASONS_BY_ID[reasonType], (label, reasonId) => ({
      id: reasonId,
      label
    }))
  }))
);

const parameterizedDispositions = Object.values(VACOLS_DISPOSITIONS_BY_ID).
  map(StringUtil.parameterize);

export const ISSUE_DISPOSITIONS = _.fromPairs(_.zip(
  _.invokeMap(parameterizedDispositions, 'toUpperCase'),
  Object.keys(VACOLS_DISPOSITIONS_BY_ID)
));

export const ISSUE_DESCRIPTION_MAX_LENGTH = VACOLS_COLUMN_MAX_LENGTHS.ISSUES.ISSDESC;
export const ATTORNEY_COMMENTS_MAX_LENGTH = VACOLS_COLUMN_MAX_LENGTHS.DECASS.DEATCOM;
export const DOCUMENT_ID_MAX_LENGTH = VACOLS_COLUMN_MAX_LENGTHS.DECASS.DEDOCID;
export const JUDGE_CASE_REVIEW_COMMENT_MAX_LENGTH = VACOLS_COLUMN_MAX_LENGTHS.DECASS.DEBMCOM;

export const PAGE_TITLES = {
  DISPOSITIONS: {
    JUDGE: 'Review Dispositions',
    ATTORNEY: 'Select Dispositions'
  },
  REMANDS: {
    JUDGE: 'Review Remand Reasons',
    ATTORNEY: 'Select Remand Reasons'
  },
  EVALUATE: 'Evaluate Decision'
};
