import React from 'react';
import PropTypes from 'prop-types';

import { rowThirds } from './style';

import TextField from '../../../components/TextField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import DateSelector from '../../../components/DateSelector';

const TranscriptionDetailsInputs = ({ transcription, update, readOnly }) => (
  <React.Fragment>
    <div {...rowThirds}>
      <TextField
        name="taskNumber"
        label="Task #"
        strongLabel
        readOnly={readOnly}
        value={transcription?.taskNumber}
        onChange={(taskNumber) => update({ taskNumber })}
      />
      <SearchableDropdown
        name="transcriber"
        label="Transcriber"
        strongLabel
        readOnly={readOnly}
        value={transcription?.transcriber}
        options={[
          {
            label: '',
            value: null
          },
          {
            label: 'Genesis Government Solutions, Inc.',
            value: 'Genesis Government Solutions, Inc.'
          },
          {
            label: 'Jamison Professional Services',
            value: 'Jamison Professional Services'
          },
          {
            label: 'The Ravens Group, Inc.',
            value: 'The Ravens Group, Inc.'
          }
        ]}
        onChange={(option) => update({ transcriber: (option || {}).value })}
      />
      <div />
    </div>
    <div {...rowThirds}>
      <DateSelector
        name="sentToTranscriberDate"
        label="Sent to Transcriber"
        strongLabel
        readOnly={readOnly}
        value={transcription?.sentToTranscriberDate}
        onChange={(sentToTranscriberDate) => update({ sentToTranscriberDate })}
      />
      <DateSelector
        name="expectedReturnDate"
        label="Expected Return Date"
        strongLabel
        readOnly={readOnly}
        value={transcription?.expectedReturnDate}
        onChange={(expectedReturnDate) => update({ expectedReturnDate })}
      />
      <DateSelector
        name="uploadedToVbmsDate"
        label="Transcript Uploaded to VBMS"
        strongLabel
        readOnly={readOnly}
        value={transcription?.uploadedToVbmsDate}
        onChange={(uploadedToVbmsDate) => update({ uploadedToVbmsDate })}
      />
    </div>
  </React.Fragment>
);

TranscriptionDetailsInputs.propTypes = {
  transcription: PropTypes.shape({
    taskNumber: PropTypes.string,
    transcriber: PropTypes.string,
    sentToTranscriberDate: PropTypes.string,
    expectedReturnDate: PropTypes.string,
    uploadedToVbmsDate: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool
};

export default TranscriptionDetailsInputs;
