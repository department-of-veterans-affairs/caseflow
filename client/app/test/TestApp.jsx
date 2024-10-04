/* eslint-disable max-lines, max-len */

import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { Switch, BrowserRouter } from 'react-router-dom';

import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import ScrollToTop from '../components/ScrollToTop';
import PageRoute from '../components/PageRoute';

import TestUsers from './TestUsers';
import TestData from './TestData';
import LoadTest from './loadTest/LoadTest';

const TestApp = (props) => {

  const routedTestUsers = () => {
    return <TestUsers {...props} />;
  };

  const routedTestData = () => {
    return <TestData {...props} />;
  };

  const routedLoadTest = () => {
    return <LoadTest {...props} />;
  };

  return <BrowserRouter basename="/test">
    <NavigationBar
      userDisplayName={props.userDisplayName}
      dropdownUrls={props.dropdownUrls}
      appName="Test"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }}
    >
      <AppFrame wideApp>
        <ScrollToTop />
        <div className="cf-wide-app">
          <Switch>
            <PageRoute
              exact
              path={['/users', '/users/me']}
              title="Test Users | Caseflow"
              render={routedTestUsers}
            />
            <PageRoute
              exact
              path="/data"
              title="Test Data | Caseflow"
              render={routedTestData}
            />
            <PageRoute
              exact
              path="/load_tests"
              title="Load Test | Caseflow"
              render={routedLoadTest}
            />
          </Switch>
        </div>
      </AppFrame>
    </NavigationBar>
  </BrowserRouter>
  ;
};

TestApp.propTypes = {
  currentUser: PropTypes.object.isRequired,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
};

export default TestApp;
