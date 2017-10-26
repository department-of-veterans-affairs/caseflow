import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';

import StuckTasksContainer from './StuckTasksContainer';
import { establishClaimAdminReducers, mapDataToInitialState } from './reducers/index';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';

const configureStore = (data) => {

  const middleware = [thunk, perflogger];

  // This is to be used with the Redux Devtools Chrome extension
  // https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd
  // eslint-disable-next-line no-underscore-dangle
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  const initialData = mapDataToInitialState(data);
  const store = createStore(
    establishClaimAdminReducers,
    initialData,
    composeEnhancers(applyMiddleware(...middleware))
  );

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers
    module.hot.accept('./reducers/index', () => {
      store.replaceReducer(establishClaimAdminReducers);
    });
  }

  return store;
};

const EstablishClaimAdmin = ({
  userDisplayName,
  dropdownUrls,
  feedbackUrl,
  buildDate
}) => {

  return <Provider store={configureStore()}>
    <div>
      <BrowserRouter basename="/dispatch/admin">
        <div>
          <NavigationBar
            appName="Establish Claim Admin"
            defaultUrl="/dispatch/admin"
            userDisplayName={userDisplayName}
            dropdownUrls={dropdownUrls}>
            <div className="cf-wide-app">
              <div className="usa-grid">
                <Route exact path="/"
                  component={() => <StuckTasksContainer/>}
                />

              </div>
            </div>
          </NavigationBar>
          <Footer
            appName="Establish Claim Admin"
            feedbackUrl={feedbackUrl}
            buildDate={buildDate}/>
        </div>
      </BrowserRouter>
    </div>
  </Provider>;
};

export default EstablishClaimAdmin;
