import { Provider } from 'react-redux';
import { createStore } from 'redux';
import React from 'react';
import DecisionReviewer from './DecisionReviewer';
import * as Constants from './constants';
import _ from 'lodash';
import { categoryFieldNameOfCategoryName } from './utils';

const initialState = {
  ui: {
    pdfList: {
      filters: {
        category: {}
      },
      filterPositions: {}
    }
  }
};
const readerReducer = (state = initialState, action = {}) => {
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
  case Constants.TOGGLE_FILTER_DROPDOWN:
    return (() => {
      const originalValue = _.get(
        state,
        ['ui', 'pdfList', 'dropdowns', action.payload.filterName],
        false
      );

      return _.merge(
        {},
        state,
        {
          ui: {
            pdfList: {
              dropdowns: {
                [action.payload.filterName]: !originalValue
              }
            }
          }
        }
      );
    })();
  case Constants.SET_FILTER_POSITION:
    return _.merge(
      {},
      state,
      {
        ui: {
          pdfList: {
            filterPositions: {
              // elem.getBoundingClientRect is a ClientRect, and if we just
              // insert it into this object, it wll show up as an empty object.
              // We can convert it to a plain object with _.merge.
              [action.payload.filterName]: _.merge({}, action.payload.boundingRect)
            }
          }
        }
      }
    );
  default:
    return state;
  }
};

const store = createStore(
  readerReducer,
  // eslint-disable-next-line no-underscore-dangle
  window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
);

const Reader = (props) => {
  return <Provider store={store}>
        <DecisionReviewer {...props} />
    </Provider>;
};

export default Reader;
