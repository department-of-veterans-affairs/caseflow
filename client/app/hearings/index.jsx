import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import HearingPrepContainer from './HearingPrepContainer';
import hearingsReducers from './reducers/index';

// eslint-disable-next-line no-underscore-dangle
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const store = createStore(hearingsReducers, composeEnhancers(applyMiddleware(thunk, perflogger)));

if (module.hot) {
  // Enable Webpack hot module replacement for reducers
  module.hot.accept('./reducers/index', () => {
    store.replaceReducer(hearingsReducers);
  });
}

const HearingPrep = (props) => {
  return <Provider store={store}>
      <HearingPrepContainer {...props} />
  </Provider>;
};

export default HearingPrep;
