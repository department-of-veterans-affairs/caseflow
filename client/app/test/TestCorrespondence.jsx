import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../components/Button';
import TextField from '../components/TextField';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import COPY from '../../COPY';

export default function TestCorrespondence(props) {
  const [correspondenceCount, setCorrespondenceCount] = useState(0);
  const [veteranFileNumbers, setVeteranFileNumbers] = useState('');

  const handleVeteranFileNumbers = (e) => {
    const inputValue = e.target.value;
    // Allow only digits and commas
    const sanitizedValue = inputValue.replace(/[^0-9,]/g, '');
    // Split the input by commas and count the number of elements
    const numbers = sanitizedValue.split(',');

    // If the number of elements exceeds 10, truncate the input
    if (numbers.length > 10) {
      setVeteranFileNumbers(numbers.slice(0, 10).join(','));
    } else {
      setVeteranFileNumbers(sanitizedValue);
    }
  };
  const handleCorrespondenceCountChange = (value) => {
    setCorrespondenceCount(value);
  };

  const handleSubmit = () => {
    // Submit the form values
    console.log('Text Area Value:', veteranFileNumbers);
    console.log('Number Value:', correspondenceCount);
    // Here you can add your logic to handle form submission (e.g., API call)
  };

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

          <TextField
            type="number"
            label={COPY.CORRESPONDENCE_ADMIN.COUNT_LABEL}
            name="correspondenceCount"
            value={correspondenceCount}
            onChange={handleCorrespondenceCountChange}
          />
          <Button
            type="button"
            name="generateCorrespondence"
            className={['cf-left-side']}
            onClick={handleSubmit}>
            {COPY.CORRESPONDENCE_ADMIN.SUBMIT_BUTTON_TEXT}
          </Button>
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
