import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import perfLogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import { getReduxAnalyticsMiddleware } from '../util/ReduxUtil';

const setupStore = ({ reducer, initialState, analyticsMiddlewareArgs, enhancers }) => {
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  const middleware = [thunk, getReduxAnalyticsMiddleware(...analyticsMiddlewareArgs)];

  // Some middleware should be skipped in test scenarios. Normally I wouldn't leave a comment
  // like this, but we had a bug where we accidentally added essential middleware here and it
  // was super hard to track down! :)
  // eslint-disable-next-line no-process-env
  if (process.env.NODE_ENV !== 'test') {
    middleware.push(perfLogger);
  }

  const composedEnhancers = composeEnhancers(applyMiddleware(...middleware), ...enhancers);

  return createStore(reducer, initialState, composedEnhancers);
};

export default function ReduxBase(props) {
  const { children, reducer, initialState, enhancers, analyticsMiddlewareArgs, getStoreRef } = props;

  const store = setupStore({ reducer,
    initialState,
    enhancers,
    analyticsMiddlewareArgs });

  // Dispatch relies on direct access to the store. It would be better to use connect(),
  // but for now, we will expose this to grant that access.
  if (getStoreRef) {
    getStoreRef(store);
  }

  return <Provider store={store}>{children}</Provider>;
}

ReduxBase.propTypes = {
  children: PropTypes.oneOfType([PropTypes.arrayOf(PropTypes.node), PropTypes.node]).isRequired,
  reducer: PropTypes.func,
  initialState: PropTypes.object,
  enhancers: PropTypes.array,
  analyticsMiddlewareArgs: PropTypes.array,
  getStoreRef: PropTypes.func
};

ReduxBase.defaultProps = {
  analyticsMiddlewareArgs: [],
  // eslint-disable-next-line no-empty-function
  getStoreRef: () => {},
  enhancers: []
};
