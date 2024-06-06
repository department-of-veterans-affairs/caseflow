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
import COPY from "../../COPY.json";

export default function TestCorrespondence(props) {

  return <BrowserRouter>
    <div>
      <NavigationBar
        wideApp
        userDisplayName={props.userDisplayName}
        dropdownUrls={props.dropdownUrls}
        applicationUrls={props.applicationUrls}
        defaultUrl="/test/correspondence"
        logoProps={{
          accentColor: COLORS.GREY_DARK,
          overlapColor: COLORS.GREY_DARK
        }} />
      <AppFrame>
        <AppSegment filledBackground>
          <h1>{COPY.CORRESPONDENCE_ADMIN.HEADER}</h1>
          <h3>{COPY.CORRESPONDENCE_ADMIN.SUB_HEADER}</h3>
          <p>{COPY.CORRESPONDENCE_ADMIN.DESCRIPTION}</p>
        </AppSegment>
      </AppFrame>
    </div>
  </BrowserRouter>;
}

TestCorrespondence.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  applicationUrls: PropTypes.array,
};
