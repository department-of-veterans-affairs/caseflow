/* eslint-disable max-lines */
import * as Constants from './constants';

import _ from 'lodash';

import { update } from '../util/ReducerUtil';
import { timeFunction } from '../util/PerfDebug';





export const initialState = {
  loadedAppealId: null,
  loadedAppeal: {},
  initialDataLoadingFail: false,
  didLoadAppealFail: false,
  initialCaseLoadingFail: false,
  ui: {
    pdf: {
      scrollToComment: null
    }
  },
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: [],
  documentSearchString: null,
  documentSearchIndex: 0,
  matchIndexToHighlight: null,
  extractedText: {}
};

export const reducer = (state = initialState, action = {}) => {

  switch (action.type) {

  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      scrollToComment: { $set: action.payload.scrollToComment }
    });
  case Constants.SET_UP_PAGE_DIMENSIONS:
    return update(
      state,
      {
        pageDimensions: {
          [`${action.payload.file}-${action.payload.pageIndex}`]: {
            $set: {
              ...action.payload.dimensions,
              file: action.payload.file,
              pageIndex: action.payload.pageIndex
            }
          }
        }
      }
    );
  case Constants.SET_PDF_DOCUMENT:
    return update(
      state,
      {
        pdfDocuments: {
          [action.payload.file]: {
            $set: action.payload.doc
          }
        }
      }
    );
  case Constants.CLEAR_PDF_DOCUMENT:
    if (action.payload.doc && _.get(state.pdfDocuments, [action.payload.file]) === action.payload.doc) {
      return update(
        state,
        {
          pdfDocuments: {
            [action.payload.file]: {
              $set: null
            }
          }
        });
    }

    return state;
  case Constants.SET_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: true
        }
      }
    });
  case Constants.CLEAR_DOCUMENT_LOAD_ERROR:
    return update(state, {
      documentErrors: {
        [action.payload.file]: {
          $set: false
        }
      }
    });
  case Constants.GET_DOCUMENT_TEXT:
    return update(
      state,
      {
        extractedText: {
          $merge: action.payload.textObject
        }
      }
    );
  case Constants.ZERO_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $set: 0
        }
      }
    );
  case Constants.UPDATE_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $apply: (index) => action.payload.increment ? index + 1 : index - 1
        }
      }
    );
  case Constants.SET_SEARCH_INDEX:
    return update(
      state,
      {
        documentSearchIndex: {
          $set: action.payload.index
        }
      }
    );
  case Constants.SET_SEARCH_INDEX_TO_HIGHLIGHT:
    return update(
      state,
      {
        matchIndexToHighlight: {
          $set: action.payload.index
        }
      }
    );
  case Constants.SET_LOADED_APPEAL_ID:
    return update(state, {
      loadedAppealId: {
        $set: action.payload.vacolsId
      }
    });

  default:
    return state;
  }
};

export default timeFunction(
  reducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
