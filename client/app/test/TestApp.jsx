/* eslint-disable max-lines, max-len */

import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { Switch } from 'react-router-dom';

import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import ScrollToTop from '../components/ScrollToTop';
import PageRoute from '../components/PageRoute';

import TestUsers from './TestUsers';

export default class TestApp extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      currentUser: props.currentUser,
    };
  }

  routedTestUsers = (props) => {
    return <TestUsers {...props}/>;
  }

  render = () => (
    <NavigationBar
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      appName="Test Users"
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
              path="/test/users"
              title="Test App"
              render={this.routedTestUsers}
            />
          </Switch>
        </div>
      </AppFrame>
    </NavigationBar>
  )
}

TestApp.propTypes = {
  currentUser: PropTypes.object.isRequired,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
};
