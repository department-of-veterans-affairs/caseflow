import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';
import _ from 'lodash';

const readerReducer = (state = {}, action = {}) => {
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
    return _.merge(
      {},
      state,
      {
        documents: {
          [action.payload.docId]: {
            [`category_${action.payload.categoryName}`]: action.payload.toggleState
          }
        }
      }
    );
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
