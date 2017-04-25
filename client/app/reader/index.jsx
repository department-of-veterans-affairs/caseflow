import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';
import update from 'immutability-helper';

const initialState = {
  ui: {
    pdfSidebar: {
      showTagErrorMsg: false
    },
    pdf: {
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
  case Constants.REQUEST_NEW_TAG_CREATION:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: false } } }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: true } } }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_SUCCESS:
    return _.merge(
      {},
      state,
      {
        documents: {
          [action.payload.docId]: {
            tags: _.union(state.documents[action.payload.docId].tags,
              action.payload.createdTags)
          }
        }
      }
    );
  case Constants.REQUEST_REMOVE_TAG_SUCCESS:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: false } } },
      documents: {
        [action.payload.docId]: {
          tags: { $set: state.documents[action.payload.docId].tags.
            filter((tag) => tag.id !== action.payload.tagId) }
        }
      }
    }
  );
  case Constants.REQUEST_REMOVE_TAG_FAILURE:
    return update(state, {
      ui: { pdfSidebar: { showTagErrorMsg: { $set: true } } }
    });
  case Constants.SET_CURRENT_RENDERED_FILE:
    return update(state, {
      ui: {
        pdfSidebar: { showTagErrorMsg: { $set: false } },
        pdf: { $merge: _.pick(action.payload, 'currentRenderedFile') }
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { $merge: _.pick(action.payload, 'scrollToComment') } }
    });
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

const store = createStore(readerReducer, initialState, applyMiddleware(thunk, logger));

const Reader = (props) => {
  return <Provider store={store}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
