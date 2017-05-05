import { docCategoryIcon } from '../components/RenderFunctions';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';
export const TOGGLE_DOCUMENT_CATEGORY_FAIL = 'TOGGLE_DOCUMENT_CATEGORY_FAIL';
export const RECEIVE_DOCUMENTS = 'RECEIVE_DOCUMENTS';
export const TOGGLE_FILTER_DROPDOWN = 'TOGGLE_FILTER_DROPDOWN';
export const SET_CATEGORY_FILTER = 'SET_CATEGORY_FILTER';
export const SET_TAG_FILTER = 'SET_TAG_FILTER';
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
export const SCROLL_TO_COMMENT = 'SCROLL_TO_COMMENT';
export const TOGGLE_COMMENT_LIST = 'TOGGLE_COMMENT_LIST';
export const TOGGLE_PDF_SIDEBAR = 'TOGGLE_PDF_SIDEBAR';
export const LAST_READ_DOCUMENT = 'LAST_READ_DOCUMENT';
export const SET_COMMENT_FLOW_STATE = 'SET_COMMENT_FLOW_STATE';
export const SCROLL_TO_SIDEBAR_COMMENT = 'SCROLL_TO_SIDEBAR_COMMENT';
export const COLLECT_ALL_TAGS_FOR_OPTIONS = 'COLLECT_ALL_TAGS_FOR_OPTIONS';
export const SET_SORT = 'SET_SORT';
export const SET_PDF_READY_TO_SHOW = 'SET_PDF_READY_TO_SHOW';
export const SET_SEARCH = 'SET_SEARCH';
export const TOGGLE_EXPAND_ALL = 'TOGGLE_EXPAND_ALL';
export const CLEAR_ALL_FILTERS = 'CLEAR_ALL_FILTERS';
export const SET_ANNOTATION_STORAGE = 'SET_ANNOTATION_STORAGE';
export const CLEAR_ALL_SEARCH = 'CLEAR_ALL_SEARCH';

// comment flow states
export const PLACING_COMMENT_STATE = 'PLACING_COMMENT';
export const WRITING_COMMENT_STATE = 'WRITING_COMMENT';

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
