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

const TranscriptionDetailsWebex = ({ transcription, title, readOnly, update }) => {
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
          <p>{transcription?.contractor || 'N/A'}</p>
        </div>
        <DateSelector
          name="uploadedToVbmsDate"
          label="Uploaded to VBMS"
          strongLabel
          type="date"
          readOnly={readOnly}
          value={transcription?.uploadedToVbmsDate}
          onChange={(uploadedToVbmsDate) => update({ uploadedToVbmsDate })}
        />
      </div>
      <div {...rowThirds}>
        <div>
          <label>Sent to Contractor</label>
          <p>{transcription?.sentToTranscriberDate || 'N/A'}</p>
        </div>
        <div>
          <label>Expected Return Date</label>
          <p>{transcription?.expectedReturnDate || 'N/A'}</p>
        </div>
        <DateSelector
          name="returnDate"
          label="Return Date"
          strongLabel
          type="date"
          readOnly={readOnly}
          value={transcription?.returnDate}
          onChange={(returnDate) => update({ returnDate })}
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
    uploadedToVbmsDate: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  title: PropTypes.string
};

export default TranscriptionDetailsWebex;
