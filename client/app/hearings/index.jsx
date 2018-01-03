import React from 'react';
import { BrowserRouter, Route, Switch } from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import perflogger from 'redux-perf-middleware';
import thunk from 'redux-thunk';
import PageRoute from '../components/PageRoute';
import { getReduxAnalyticsMiddleware } from '../util/getReduxAnalyticsMiddleware';
import DocketsContainer from './containers/DocketsContainer';
import DailyDocketContainer from './containers/DailyDocketContainer';
import HearingWorksheetContainer from './containers//HearingWorksheetContainer';
import { hearingsReducers, mapDataToInitialState } from './reducers/index';
import ScrollToTop from './util/ScrollTop';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import AppFrame from '../components/AppFrame';

const configureStore = (data) => {

  const middleware = [thunk, perflogger, getReduxAnalyticsMiddleware()];

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
    <BrowserRouter>
      <Switch>
        <Route exact path="/hearings/:hearingId/worksheet/print"
          breadcrumb="Daily Docket > Hearing Worksheet"
          component={(props) => (
            <HearingWorksheetContainer
              print
              veteran_law_judge={hearings.veteran_law_judge}
              hearingId={props.match.params.hearingId} />
          )}
        />
        <Route>
          <div>
            <NavigationBar
              appName="Hearing Prep"
              defaultUrl="/hearings/dockets"
              userDisplayName={hearings.userDisplayName}
              dropdownUrls={hearings.dropdownUrls}>
              <AppFrame>
                <ScrollToTop />
                <PageRoute exact path="/hearings/dockets"
                  title="Your Hearing Days"
                  component={() => <DocketsContainer veteranLawJudge={hearings.veteran_law_judge} />} />

                <PageRoute exact path="/hearings/dockets/:date"
                  breadcrumb="Daily Docket"
                  title="Daily Docket"
                  component={(props) => (
                    <DailyDocketContainer
                      veteran_law_judge={hearings.veteran_law_judge}
                      date={props.match.params.date} />
                  )}
                />

                <Route exact path="/hearings/:hearingId/worksheet"
                  breadcrumb="Daily Docket > Hearing Worksheet"
                  component={(props) => (
                    <HearingWorksheetContainer
                      veteran_law_judge={hearings.veteran_law_judge}
                      hearingId={props.match.params.hearingId} />
                  )}
                />

              </AppFrame>
            </NavigationBar>
            <Footer
              appName="Hearing Prep"
              feedbackUrl={hearings.feedbackUrl}
              buildDate={hearings.buildDate} />
          </div>
        </Route>
      </Switch>
    </BrowserRouter>
  </Provider>;
};

export default Hearings;
