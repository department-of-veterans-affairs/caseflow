import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';

/**
 * Creates the Redux store and configures it with various tools
 * and middleware used across Caseflow apps.
 */

const configureStore = ({ reducers, initialState = null, moreMiddleware = null }) => {
  // Redux middleware
  const middleware = [];
  if (!ConfigUtil.test()) {
    middleware.push(thunk, perflogger);
  }

  if (moreMiddleware) {
    middleware = middleware.concat(moreMiddleware);
  }

  // This configures the Redux Devtools Chrome extension.
  // See: https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  // Strings all the middleware together, so it is invoked in order.
  const enhancers  = composeEnhancers(applyMiddleware(...middleware));

  // Only some apps will provide initial data for the store.
  if (initialState) {
    const store = createStore(
      reducers,
      initialState,
      enhancers
    );
  } else {
    const store = createStore(
      reducers,
      enhancers
    );
  }

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers.
    // Changes made to the reducers while developing should be
    // available instantly.
    // Note that this expects the global reducer for each app
    // to be present at reducers/index.
    module.hot.accept('./reducers/index', () => {
      store.replaceReducer(reducers);
    });
  }

  return store;
}

export configureStore;
