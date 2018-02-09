import { css } from 'glamor';

export const COLORS = {
  QUEUE_LOGO_PRIMARY: '#11598D',
  QUEUE_LOGO_OVERLAP: '#0E456C',
  QUEUE_LOGO_BACKGROUND: '#D6D7D9'
};

export const ACTIONS = {
  RECEIVE_QUEUE_DETAILS: 'RECEIVE_QUEUE_DETAILS',
  SET_LOADED_QUEUE_ID: 'SET_LOADED_QUEUE_ID',
  SET_APPEAL_DOC_COUNT: 'SET_APPEAL_DOC_COUNT',
  LOAD_APPEAL_DOC_COUNT_FAILURE: 'LOAD_APPEAL_DOC_COUNT_FAILURE'
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
  VIEW_QUEUE_TABLE: 'view-queue-table',
  VIEW_QUEUE_TASK: 'view-queue-task',
  QUEUE_TO_READER: 'queue-to-reader',
  QUEUE_TO_HEARING_WORKSHEET: 'queue-to-hearing-worksheet'
};

export const INTERACTION_TYPES = {
  SAME_WINDOW: 'same-window'
};
