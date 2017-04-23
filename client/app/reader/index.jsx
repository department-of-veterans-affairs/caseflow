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
    showTagErrorMsg: false,
    allCommentsExpanded: false,
    pdf: {
    }
  },
  documents: {
  }
};

// reusable functions
const expandCollapseAllComments = (state, showAllComments) => {
  return update(state, {
    documents: {
      $set: _.mapValues(state.documents, (document) => {
        return update(document, { listComments: { $set: showAllComments } });
      })
    },
    ui: {
      $merge: { allCommentsExpanded: showAllComments }
    }
  });
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
      ui: { showTagErrorMsg: { $set: false } }
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return update(state, {
      ui: { showTagErrorMsg: { $set: true } }
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
      ui: { showTagErrorMsg: { $set: false } },
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
      ui: { showTagErrorMsg: { $set: true } }
    });
  case Constants.SET_CURRENT_RENDERED_FILE:
    return update(state, {
      ui: {
        showTagErrorMsg: { $set: false },
        pdf: { $merge: _.pick(action.payload, 'currentRenderedFile') }
      }
    });
  case Constants.SCROLL_TO_COMMENT:
    return update(state, {
      ui: { pdf: { $merge: _.pick(action.payload, 'scrollToComment') } }
    });
  case Constants.EXPAND_ALL_PDF_COMMENT_LIST:
    return expandCollapseAllComments(state, true);
  case Constants.COLLAPSE_ALL_PDF_COMMENT_LIST:
    return expandCollapseAllComments(state, false);
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
