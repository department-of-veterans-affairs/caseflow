import { docCategoryIcon } from '../components/RenderFunctions';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';
export const RECEIVE_DOCUMENTS = 'RECEIVE_DOCUMENTS';
export const ADD_NEW_TAG = 'ADD_NEW_TAG';
export const REMOVE_TAG = 'REMOVE_TAG';
export const REQUEST_NEW_TAG_CREATION_SUCCESS = 'REQUEST_NEW_TAG_CREATION_SUCCESS';
export const REQUEST_NEW_TAG_CREATION_FAILURE = 'REQUEST_NEW_TAG_CREATION_FAILURE';
export const REQUEST_NEW_TAG_CREATION = 'REQUEST_NEW_TAG_CREATION';
export const REQUEST_REMOVE_TAG = 'REQUEST_REMOVE_TAG';
export const REQUEST_REMOVE_TAG_SUCCESS = 'REQUEST_REMOVE_TAG_SUCCESS';
export const REQUEST_REMOVE_TAG_FAILURE = 'REQUEST_REMOVE_TAG_FAILURE';
export const SELECT_CURRENT_VIEWER_PDF = 'SELECT_CURRENT_VIEWER_PDF';
export const SHOW_NEXT_PDF = 'SHOW_NEXT_PDF';
export const SHOW_PREV_PDF = 'SHOW_PREV_PDF';
export const SET_CURRENT_RENDERED_FILE = 'SET_CURRENT_RENDERED_FILE';
export const SCROLL_TO_COMMENT = 'SCROLL_TO_COMMENT';
export const TOGGLE_COMMENT_LIST = 'TOGGLE_COMMENT_LIST';
export const LAST_READ_DOCUMENT = 'LAST_READ_DOCUMENT';
export const SCROLL_TO_SIDEBAR_COMMENT = 'SCROLL_TO_SIDEBAR_COMMENT';

export const documentCategories = {
  procedural: {
    renderOrder: 0,
    humanName: 'Procedural',
    svg: docCategoryIcon('#4A90E2')
  },
  medical: {
    renderOrder: 1,
    humanName: 'Medical',
    svg: docCategoryIcon('#FF6868')
  },
  other: {
    renderOrder: 2,
    humanName: 'Other Evidence',
    svg: docCategoryIcon('#5BD998')
  }
};
