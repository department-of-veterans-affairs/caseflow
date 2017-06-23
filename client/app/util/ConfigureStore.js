import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import logger from 'redux-logger';

import ConfigUtil from './ConfigUtil';

/**
 * Creates the Redux store and configures it with various tools
 * and middleware used across Caseflow apps.
 */
export default function configureStore({ reducers, initialState }) {
  if (!reducers) {
    throw "No reducer given!"
  }
  // Redux middleware
  let middleware = [];
  if (!ConfigUtil.test()) {
    // Note: logger must be the last middleware in chain,
    // otherwise it will log thunk and promise, not actual actions
    middleware.push(thunk, perflogger, logger);
  }

  // This configures the Redux Devtools Chrome extension.
  // See: https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  // Strings all the middleware together, so it is invoked in order.
  const enhancers  = composeEnhancers(applyMiddleware(...middleware));

  // Only some apps will provide initial data for the store.
  const store = initialState ?
    createStore(reducers, initialState, enhancers) :
    createStore(reducers, enhancers);

  return store;
};
