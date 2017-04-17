import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';

const intialState = {
  currentPdfIndex: null
};

const readerReducer = (state = intialState, action = {}) => {
  let categoryKey;

  switch (action.type) {
  case Contants.SELECT_CURRENT_VIEWER_PDF:
    return _.merge(
      {},
      state,
      {
        currentPdfIndex: action.payload.docId
      }
    );
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
  case Constants.ADD_NEW_TAG:
    return _.merge(
      {},
      state,
      {
        documents: {
          [action.payload.docId]: {
            tags: action.payload.toggleState
          }
        }
      }
    );
  case Constants.UPDATE_DOCUMENT_TAG_LIST:
    return _.merge(
      {},
      state,
      {
        documents: {
          [action.payload.docId]: {
            tags: _.union(state.documents[action.payload.docId].tags, action.payload.createdTags)
          }
        }
      }
    )
  default:
    return state;
  }
};

const store = (intialState) => { return createStore(readerReducer, applyMiddleware(thunk, logger)); }

const Reader = (props) => {
  return <Provider store={store()}>
    <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
