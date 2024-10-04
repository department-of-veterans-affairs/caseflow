import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';
import NumberField from '../components/NumberField';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import NavigationBar from '../components/NavigationBar';
import AppFrame from '../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import ApiUtil from '../util/ApiUtil';
import COPY from '../../COPY';
import Alert from 'app/components/Alert';

export default function TestCorrespondence(props) {
  const [correspondenceCount, setCorrespondenceCount] = useState(null);
  const [veteranFileNumbers, setVeteranFileNumbers] = useState('');
  const [showInvalidVeteransBanner, setShowInvalidVeteransBanner] = useState(false);
  const [showSuccessBanner, setShowSuccessBanner] = useState(false);
  const [invalidFileNumbers, setInvalidFileNumbers] = useState('');
  const [validFileNumbers, setValidFileNumbers] = useState('');
  const [correspondenceSize, setCorrespondenceSize] = useState(0);
  const [disabled, setDisabled] = useState(true);

  const handleVeteranFileNumbers = (inputValue) => {
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
    // setCorrespondenceCount(value === '' ? null : Number(value));
    if (value === '') {
      setCorrespondenceCount(null);
    } else {
      const num = Number(value);

      if (num >= 1 && num <= 40) {
        setCorrespondenceCount(num);
      }
    }
  };

  const generateCorrespondence = async () => {
    let payload = {
      file_numbers: veteranFileNumbers,
      count: correspondenceCount
    };
    const res = await ApiUtil.post('/test/correspondence/generate_correspondence', { data: payload });
    const data = res.body;

    // eslint-disable-next-line camelcase
    if (data?.invalid_file_numbers.length) {
      setInvalidFileNumbers(data.invalid_file_numbers);
      setShowInvalidVeteransBanner(true);
    } else {
      setInvalidFileNumbers('');
      setShowInvalidVeteransBanner(false);
    }

    // eslint-disable-next-line camelcase
    if (data?.valid_file_nums.length) {
      setValidFileNumbers(data.valid_file_nums);
      setShowSuccessBanner(true);
      setCorrespondenceSize(correspondenceCount);

      setCorrespondenceCount(null);
      setVeteranFileNumbers('');
    } else {
      setValidFileNumbers('');
      setShowSuccessBanner(false);
    }
  };

  const handleSubmit = () => {
    generateCorrespondence().then((res) => res);
  };

  useEffect(() => {
    if (veteranFileNumbers && correspondenceCount > 0) {
      setDisabled(false);
    } else {
      setDisabled(true);
    }
  }, [veteranFileNumbers, correspondenceCount]);

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
        {
          showSuccessBanner &&
            <div style={{ padding: '10px' }}>
              <Alert
                type="success"
                title={COPY.CORRESPONDENCE_ADMIN.SUCCESS.TITLE}
                message={correspondenceSize + COPY.CORRESPONDENCE_ADMIN.SUCCESS.MESSAGE + validFileNumbers} />
            </div>
        }
        {
          showInvalidVeteransBanner &&
            <div style={{ padding: '10px' }}>
              <Alert
                type="warning"
                title={COPY.CORRESPONDENCE_ADMIN.INVALID_ERROR.TITLE}
                message={COPY.CORRESPONDENCE_ADMIN.INVALID_ERROR.MESSAGE + invalidFileNumbers} />
            </div>
        }
        <AppSegment filledBackground>
          <div className="correspondence-admin-container">
            <h1>{COPY.CORRESPONDENCE_ADMIN.HEADER}</h1>
            <h3>{COPY.CORRESPONDENCE_ADMIN.SUB_HEADER}</h3>
            <p>{COPY.CORRESPONDENCE_ADMIN.DESCRIPTION}</p>
            <div className="textarea-div-styling-test-correspondence">
              <TextareaField
                id= "textarea-styling-test-correspondence"
                name="Enter up to 10 veteran file numbers separated by a comma."
                onChange={(val) => handleVeteranFileNumbers(val)}
                value={veteranFileNumbers}
              />
            </div>
            <NumberField
              name={COPY.CORRESPONDENCE_ADMIN.COUNT_LABEL}
              type="number"
              value={correspondenceCount === null ? '' : correspondenceCount}
              onChange={handleCorrespondenceCountChange}
              className={['correspondence-number']}
              min={1}
              max={40}
            />
            <Button
              name="Generate correspondence"
              onClick={handleSubmit}
              disabled={disabled}
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
