
import _ from 'lodash';

import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  scrollToComment: null,
  pageDimensions: {},
  pdfDocuments: {},
  documentErrors: {},
  text: []
};

export const pdfReducer = (state = initialState, action = {}) => {

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
          [action.payload.file]: {
            $set: {
              ...action.payload.dimensions
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
  default:
    return state;
  }
};

export default pdfReducer;
