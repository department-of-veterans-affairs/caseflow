import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';

import ConfigUtil from '../util/ConfigUtil';
import Dockets from './Dockets';
import { hearingsReducers, mapDataToInitialState } from './reducers/index';

const configureStore = (data) => {

  const middleware = [];

  if (!ConfigUtil.test()) {
    middleware.push(thunk, perflogger);
  }

  // This is to be used with the Redux Devtools Chrome extension
  // https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  const initialData = mapDataToInitialState(data);
  const store = createStore(
    hearingsReducers,
    initialData,
    composeEnhancers(applyMiddleware(...middleware))
  );

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept('./reducers/index', () => {
      store.replaceReducer(hearingsReducers);
    });
  }

  return store;
};

const Hearings = ({ hearings }) => {

  return <Provider store={configureStore(hearings)}>
    <div>
      <BrowserRouter>
        <div>
        <Route path="/hearings/dockets"
          component={Dockets} />
      </div>
      </BrowserRouter>
    </div>
  </Provider>;
};

export default Hearings;
