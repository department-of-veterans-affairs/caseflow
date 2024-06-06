import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import StringUtil from '../util/StringUtil';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import TabWindow from '../components/TabWindow';
import TextField from '../components/TextField';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import Alert from '../components/Alert';
import { trim, escapeRegExp } from 'lodash';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

export default function TestCorrespondence(props) {

  return <BrowserRouter>
    <div>
      <NavigationBar
        userDisplayName={props.userDisplayName}
        dropdownUrls={props.dropdownUrls}
        appName="Correspondence Admin"
        logoProps={{
          accentColor: COLORS.GREY_DARK,
          overlapColor: COLORS.GREY_DARK
        }} />
      <AppFrame>
        <AppSegment filledBackground>
          <h1>Correspondence admin</h1>
          <h3>Correspondence generation process</h3>
          <p>
            Unassigned correspondence can be created below by entering the veteran file number(s) and the number of
            correspondence needed. This number of correspondence will appear in the unassigned tab of the Correspondence
            Team Queue and will be associated to the specific veteran(s) listed below.</p>
        </AppSegment>
      </AppFrame>
    </div>
  </BrowserRouter>;
}

TestCorrespondence.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
};
