import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';

const initialState = {
  ui: {
    pdf: {
      hidePdfSidebar: false
    },
    pdfList: {
      lastReadDocId: null
    }
  },
  documents: {
  }
};

export const readerReducer = (state = initialState, action = {}) => {
  let categoryKey;

  switch (action.type) {
  case Constants.RECEIVE_DOCUMENTS:
    return _.merge(
      {},
      state,
      {
        documents: _(action.payload).
          map((doc) => [doc.id, doc]).
          fromPairs().
          value()
      }
    );
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    categoryKey = categoryFieldNameOfCategoryName(action.payload.categoryName);

    return _.merge(
      {},
      state,
      {
        documents: {
          [action.payload.docId]: {
            [categoryKey]: action.payload.toggleState
          }
        }
      }
    );
  case Constants.SET_CURRENT_RENDERED_FILE:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdf: _.pick(action.payload, 'currentRenderedFile')
        }
      }
    );
  case Constants.SCROLL_TO_COMMENT:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdf: _.pick(action.payload, 'scrollToComment')
        }
      }
    );
  case Constants.TOGGLE_COMMENT_LIST:
    return _.merge(
      {},
      state,
      {
        documents: {
          [action.payload.docId]: {
            listComments: !state.documents[action.payload.docId].listComments
          }
        }
      }
    );
  case Constants.TOGGLE_PDF_SIDEBAR:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdf: {
            hidePdfSidebar: !state.ui.pdf.hidePdfSidebar
          }
        }
      }
    );
  case Constants.LAST_READ_DOCUMENT:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdfList: {
            lastReadDocId: action.payload.docId
          }
        }
      }
    );
  default:
    return state;
  }
};

const store = createStore(readerReducer, initialState, applyMiddleware(logger));

const Reader = (props) => {
  return <Provider store={store}>
        <DecisionReviewer {...props} />
    </Provider>;
};

export default Reader;
