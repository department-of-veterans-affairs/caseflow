import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';

const intialState = {
  currentPdfIndex: null,
  currentDocId: null,
  tagsErrorMessage: ''
};

const readerReducer = (state = intialState, action = {}) => {
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
    return Object.assign({}, state, {
      tagsErrorMessage: ''
    });
  case Constants.REQUEST_NEW_TAG_CREATION_FAILURE:
    return Object.assign({}, state, {
      tagsErrorMessage: action.payload.errorMessage
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
  case Constants.SHOW_PREV_PDF:
    return state;
  case Constants.SHOW_NEXT_PDF:
    return state;
  case Constants.UPDATE_SHOWING_DOC:
    return Object.assign({}, state, {
      currentDocId: action.payload.currentDocId,
      tagsErrorMessage: ''
    });
  default:
    return state;
  }
};

const store = (intialState) => {
  return createStore(readerReducer, applyMiddleware(thunk, logger));
};

const Reader = (props) => {
  return <Provider store={store()}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
