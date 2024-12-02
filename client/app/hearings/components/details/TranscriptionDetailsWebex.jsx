import React from 'react';
import PropTypes from 'prop-types';
import { rowThirds } from './style';
import DateSelector from '../../../components/DateSelector';

const labelStyles = {
  fontWeight: 'bold'
};

const pStyles = {
  marginTop: '2rem'
};

/**
 * Formats a YYYY-MM-DD to be MM/DD/YYYY instead
 * @param {string} date - The date string to be formatted
 * @returns the formatted date
 */
const formatDate = (date) => {
  if (!date) {
    return null;
  }
  const arr = date.split('-');

  arr.push(arr.shift());

  return arr.join('/');
};

/**
 * Validates the return date by making sure its past the expected return date
 * @param {string} returnDate - The actual return date string
 * @param {string} expectedReturnDate - The expected return date string
 * @returns a boolean determining if the return date is valid
 */
const validateReturnDate = (returnDate, expectedReturnDate) => {
  if (!returnDate || !expectedReturnDate) {
    return null;
  }

  return new Date(returnDate) > new Date(expectedReturnDate);
};

const TranscriptionDetailsWebex = ({ transcription, title, readOnly }) => {
  return (
    <div data-testid="transcription-details-webex">
      <h2>{title}</h2>
      <div {...rowThirds}>
        <div>
          <label style={labelStyles}>Task #</label>
          <p style={pStyles}>{transcription?.taskNumber || 'N/A'}</p>
        </div>
        <div>
          <label style={labelStyles}>Contractor</label>
          <p style={pStyles}>{transcription?.transcriber || 'N/A'}</p>
        </div>
        <DateSelector
          name="uploadedToVbmsDate"
          label="Uploaded to VBMS"
          strongLabel
          type="date"
          readOnly={readOnly}
          value={transcription?.uploadedToVbmsDate}
        />
      </div>
      <div {...rowThirds}>
        <div>
          <label style={labelStyles}>Sent to Contractor</label>
          <p style={pStyles}>{formatDate(transcription.sentToTranscriberDate) || 'N/A'}</p>
        </div>
        <div>
          <label style={labelStyles}>Expected Return Date</label>
          <p style={pStyles}>{(formatDate(transcription.expectedReturnDate)) || 'N/A'}</p>
        </div>
        <DateSelector
          name="returnDate"
          label="Return Date"
          strongLabel
          type="date"
          readOnly={readOnly}
          value={
            (validateReturnDate(transcription.returnDate, transcription.sentToTranscriberDate) &&
              transcription?.returnDate) || 'N/A'}
        />
      </div>
    </div>
  );
};

TranscriptionDetailsWebex.propTypes = {
  transcription: PropTypes.shape({
    taskNumber: PropTypes.string,
    transcriber: PropTypes.string,
    sentToTranscriberDate: PropTypes.string,
    expectedReturnDate: PropTypes.string,
    uploadedToVbmsDate: PropTypes.string,
    returnDate: PropTypes.string
  }),
  readOnly: PropTypes.bool,
  title: PropTypes.string
};

export default TranscriptionDetailsWebex;
