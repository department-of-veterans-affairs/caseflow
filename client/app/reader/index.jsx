import React from 'react';
import { Provider } from 'react-redux';
import configureStore from '../util/ConfigureStore';
import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import readerReducer from './reducer';

// const store = configureStore({ reducers: readerReducer });
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const store = createStore(readerReducer, composeEnhancers(applyMiddleware(thunk, perflogger)));

if (module.hot) {
  // Enable Webpack hot module replacement for reducers.
  // Changes made to the reducers while developing should be
  // available instantly.
  // Note that this expects the global reducer for each app
  // to be present at reducers/index.
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
