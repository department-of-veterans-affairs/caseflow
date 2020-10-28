import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'react-redux';
import { configureStore, getDefaultMiddleware } from '@reduxjs/toolkit';
import perfLogger from 'redux-perf-middleware';
import { getReduxAnalyticsMiddleware } from '../util/ReduxUtil';

const setupStore = ({ reducer, initialState, analyticsMiddlewareArgs }) => {
  const middleware = [
    ...getDefaultMiddleware({ immutableCheck: false }),
    getReduxAnalyticsMiddleware(...analyticsMiddlewareArgs),
  ];

  // Some middleware should be skipped in test scenarios. Normally I wouldn't leave a comment
  // like this, but we had a bug where we accidentally added essential middleware here and it
  // was super hard to track down! :)
  // eslint-disable-next-line no-process-env
  if (process.env.NODE_ENV !== 'test') {
    middleware.push(perfLogger);
  }

  const store = configureStore({
    reducer,
    preloadedState: initialState,
    middleware,
  });

  return store;
};

export default function ReduxBase(props) {
  const {
    children,
    reducer,
    initialState,
    analyticsMiddlewareArgs,
    getStoreRef,
  } = props;

  const store = setupStore({
    reducer,
    initialState,
    analyticsMiddlewareArgs,
  });

  // Dispatch relies on direct access to the store. It would be better to use connect(),
  // but for now, we will expose this to grant that access.
  if (getStoreRef) {
    getStoreRef(store);
  }

  return <Provider store={store}>{children}</Provider>;
}

ReduxBase.propTypes = {
  children: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.node),
    PropTypes.node,
  ]).isRequired,
  reducer: PropTypes.func,
  initialState: PropTypes.object,
  analyticsMiddlewareArgs: PropTypes.array,
  getStoreRef: PropTypes.func,
};

ReduxBase.defaultProps = {
  analyticsMiddlewareArgs: [],
  // eslint-disable-next-line no-empty-function
  getStoreRef: () => {},
};
