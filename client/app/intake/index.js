import React from 'react';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import { createStore, applyMiddleware, compose } from 'redux';
import perfLogger from 'redux-perf-middleware';
import IntakeFrame from './IntakeFrame';
import reducer from './redux/reducer';
import { reduxAnalyticsMiddleware } from '../reader/analytics';

const Intake = (props) => {
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
  const store = createStore(
    reducer,
    composeEnhancers(applyMiddleware(thunk, perfLogger, reduxAnalyticsMiddleware))
  );

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept('./redux/reducer', () => {
      store.replaceReducer(reducer);
    });
  }

  return <Provider store={store}>
      <IntakeFrame {...props} />
  </Provider>;
};

export default Intake;
