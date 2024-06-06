import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import StringUtil from '../util/StringUtil';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import TabWindow from '../components/TabWindow';
import TextareaField from '../components/TextareaField';
import NumberField from '../components/NumberField';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import Alert from '../components/Alert';
import { trim, escapeRegExp } from 'lodash';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY.json';

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
          <div className="textarea-div-styling-test-correspondence">
            <TextareaField
              id= "textarea-styling-test-correspondence"
              name="Enter up to 10 veteran file numbers separated by a comma."
            />
          </div>
          <p>Enter the number of correspondence to be generated</p>
          <div>
            <NumberField
              className={['number-field-styling-test-correspondence']}
            />
          </div>
          <div>
            <Button
              name="Generate correspondence"
              classNames={['correspondence-intake-appeal-button']}
            />
          </div>
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
