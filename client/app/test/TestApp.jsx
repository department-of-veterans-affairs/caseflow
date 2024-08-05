/* eslint-disable max-lines, max-len */

import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

import NavigationBar from '../components/NavigationBar';

export default class TestApp extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      currentUser: props.currentUser,
    };
  }

  render = () => (
    <NavigationBar
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      appName="Test Users"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }} />
  )
}

TestApp.propTypes = {
  currentUser: PropTypes.object.isRequired,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
};
