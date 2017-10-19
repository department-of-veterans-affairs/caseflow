import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose, combineReducers } from 'redux';
import perfLogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import readerReducer from './reducer';
import { reduxAnalyticsMiddleware } from './analytics';
import { reducer as searchReducer, reduxSearch } from 'redux-search';

// eslint-disable-next-line no-underscore-dangle
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const store = createStore(
  combineReducers({
    readerReducer,
    search: searchReducer
  }),
  composeEnhancers(
    applyMiddleware(thunk, perfLogger, reduxAnalyticsMiddleware),
    reduxSearch({
      // Configure redux-search by telling it which resources to index for searching
      resourceIndexes: {
        // In this example Books will be searchable by :title and :author
        extractedText: ['text']
      },
      // This selector is responsible for returning each collection of searchable resources
      resourceSelector: (resourceName, state) => {
        // In our example, all resources are stored in the state under a :resources Map
        // For example "books" are stored under state.resources.books
        return state.readerReducer[resourceName];
      }
    })
  )
);

if (module.hot) {
  // Enable Webpack hot module replacement for reducers
  module.hot.accept('./reducer', () => {
    store.replaceReducer(readerReducer);
  });
}

const Reader = (props) => {
  return <Provider store={store}>
    <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
