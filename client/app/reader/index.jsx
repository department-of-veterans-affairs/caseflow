import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import logger from 'redux-logger';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';

const readerReducer = (state = {}, action = {}) => {
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
