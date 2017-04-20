import { docCategoryIcon } from '../components/RenderFunctions';

// actions
export const TOGGLE_DOCUMENT_CATEGORY = 'TOGGLE_DOCUMENT_CATEGORY';
export const RECEIVE_DOCUMENTS = 'RECEIVE_DOCUMENTS';
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
