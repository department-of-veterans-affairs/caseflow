import React from 'react';
import PropTypes from 'prop-types';
import { rowThirds } from './style';
import DateSelector from '../../../components/DateSelector';
import { css } from 'glamor';

const detailStyles = css({
  '& label': {
    fontWeight: 'bold',
  },
  '& p': {
    marginTop: '2rem'
  }
});

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
    <div {...detailStyles}>
      <h2>{title}</h2>
      <div {...rowThirds}>
        <div>
          <label>Task #</label>
          <p>{transcription?.taskNumber || 'N/A'}</p>
        </div>
        <div>
          <label>Contractor</label>
          <p>{transcription?.transcriber || 'N/A'}</p>
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
          <label>Sent to Contractor</label>
          <p>{formatDate(transcription.sentToTranscriberDate) || 'N/A'}</p>
        </div>
        <div>
          <label>Expected Return Date</label>
          <p>{(formatDate(transcription.expectedReturnDate)) || 'N/A'}</p>
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
