/* eslint-disable max-lines */
import { css } from 'glamor';
import _ from 'lodash';
import VACOLS_DISPOSITIONS_BY_ID from '../../constants/VACOLS_DISPOSITIONS_BY_ID.json';
import ISSUE_DISPOSITIONS_BY_ID from '../../constants/ISSUE_DISPOSITIONS_BY_ID.json';
import LEGACY_REMAND_REASONS_BY_ID from '../../constants/LEGACY_ACTIVE_REMAND_REASONS_BY_ID.json';
import REMAND_REASONS_BY_ID from '../../constants/AMA_REMAND_REASONS_BY_ID.json';
import StringUtil from '../util/StringUtil';
import { COLORS as COMMON_COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';
import VACOLS_COLUMN_MAX_LENGTHS from '../../constants/VACOLS_COLUMN_MAX_LENGTHS.json';
import LEGACY_APPEAL_TYPES_BY_ID from '../../constants/LEGACY_APPEAL_TYPES_BY_ID.json';

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
  ERROR_ON_RECEIVE_DOCUMENT_COUNT: 'ERROR_ON_RECEIVE_DOCUMENT_COUNT',
  STARTED_DOC_COUNT_REQUEST: 'STARTED_DOC_COUNT_REQUEST',
  STARTED_LOADING_DOCUMENTS: 'STARTED_LOADING_DOCUMENTS',
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
  SET_MOST_RECENTLY_HELD_HEARING_FOR_APPEAL: 'SET_MOST_RECENTLY_HELD_HEARING_FOR_APPEAL',
  ERROR_ON_RECEIVE_HEARING_FOR_APPEAL: 'ERROR_ON_RECEIVE_HEARING_FOR_APPEAL',
  START_ASSIGN_TASKS_TO_USER: 'START_ASSIGN_TASKS_TO_USER',
  SET_PENDING_DISTRIBUTION: 'SET_PENDING_DISTRIBUTION',
  RECEIVE_ALL_ATTORNEYS: 'RECEIVE_ALL_ATTORNEYS',
  ERROR_LOADING_ATTORNEYS: 'ERROR_LOADING_ATTORNEYS',
  RECEIVE_TASKS: 'RECEIVE_TASKS',
  RECEIVE_APPEAL_DETAILS: 'RECEIVE_APPEAL_DETAILS',
  RECEIVE_CLAIM_REVIEW_DETAILS: 'RECEIVE_CLAIM_REVIEW_DETAILS',
  SET_TASK_ATTRS: 'SET_TASK_ATTRS',
  SET_SPECIAL_ISSUE: 'SET_SPECIAL_ISSUE',
  SET_APPEAL_AOD: 'SET_APPEAL_AOD',
  STARTED_LOADING_APPEAL_VALUE: 'STARTED_LOADING_APPEAL_VALUE',
  RECEIVE_APPEAL_VALUE: 'RECEIVE_APPEAL_VALUE',
  ERROR_ON_RECEIVE_APPEAL_VALUE: 'ERROR_ON_RECEIVE_APPEAL_VALUE',
  SET_APPEAL_ATTRS: 'SET_APPEAL_ATTRS',
  RECEIVE_AMA_TASKS: 'RECEIVE_AMA_TASKS'
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

const formatRemandReasons = (reasons) => Object.assign({},
  ...Object.keys(reasons).map((reasonType) => ({
    [reasonType]: _.map(reasons[reasonType], (label, id) => ({
      id,
      label
    }))
  }))
);

export const LEGACY_REMAND_REASONS = formatRemandReasons(LEGACY_REMAND_REASONS_BY_ID);
export const REMAND_REASONS = formatRemandReasons(REMAND_REASONS_BY_ID);

const parameterizedDispositions = Object.values(VACOLS_DISPOSITIONS_BY_ID).
  map(StringUtil.parameterize);

export const VACOLS_DISPOSITIONS = _.fromPairs(_.zip(
  _.invokeMap(parameterizedDispositions, 'toUpperCase'),
  Object.keys(VACOLS_DISPOSITIONS_BY_ID)
));

export const ISSUE_DISPOSITIONS = _.fromPairs(_.zip(
  _.invokeMap(_.keys(ISSUE_DISPOSITIONS_BY_ID), 'toUpperCase'),
  _.keys(ISSUE_DISPOSITIONS_BY_ID)
));

export const LEGACY_APPEAL_TYPES = _.fromPairs(_.zip(
  _.invokeMap(_.keys(LEGACY_APPEAL_TYPES_BY_ID), 'toUpperCase'),
  _.values(LEGACY_APPEAL_TYPES_BY_ID)
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

export const COLOCATED_HOLD_DURATIONS = [15, 30, 45, 60, 90, 120, 'Custom'];

export const COLUMN_NAMES = {
  'appeal.caseType': 'Case Type',
  'appeal.docketName': 'Docket Number',
  label: 'Task(s)',
  type: 'Type'
};

export const DOCKET_NAME_FILTERS = {
  direct_review: 'Direct Review',
  legacy: 'Legacy',
  hearing: 'Hearing',
  evidence_submission: 'Evidence'
};
