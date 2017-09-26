import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose, combineReducers } from 'redux';
import perfLogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import readerReducer from './reducer';
import { reduxAnalyticsMiddleware } from './analytics';


const configureStore = () => {
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
  const store = createStore(
    combineReducers({
      readerReducer
    }),
    composeEnhancers(applyMiddleware(thunk, perfLogger, reduxAnalyticsMiddleware))
  );

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept('./reducer', () => {
      store.replaceReducer(readerReducer);
    });
  }
}

const Reader = (props) => {
  return <Provider store={configureStore()}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
