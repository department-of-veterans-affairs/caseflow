import { docCategoryIcon } from '../components/RenderFunctions';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';
export const RECEIVE_DOCUMENTS = 'RECEIVE_DOCUMENTS';
export const ADD_NEW_TAG = 'ADD_NEW_TAG';
export const REMOVE_TAG = 'REMOVE_TAG';
export const UPDATE_DOCUMENT_TAG_LIST = 'UPDATE_DOCUMENT_TAG_LIST';
export const SHOW_TAG_SAVE_ERROR_MESSAGE = 'SHOW_TAG_SAVE_ERROR_MESSAGE';
export const REQUEST_NEW_TAG_CREATION = 'REQUEST_NEW_TAG_CREATION';
export const SELECT_CURRENT_VIEWER_PDF = 'SELECT_CURRENT_VIEWER_PDF';

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
