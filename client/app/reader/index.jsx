import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';

const readerReducer = (state = {}, action = {}) => {
  switch (action.type) {
  case Constants.TOGGLE_DOCUMENT_CATEGORY:
    return {
      ...state,
      document: {
        [action.payload.docId]: {
          categories: {
            [action.payload.categoryName]: action.payload.toggleState
          }
        }
      }
    };
  default:
    return state;
  }
};

const store = createStore(readerReducer, null, applyMiddleware(logger));

const Reader = (props) => {
  return <Provider store={store}>
        <DecisionReviewer {...props} />
    </Provider>;
};

export default Reader;
