import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { rowThirds } from './style';

import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import DateSelector from '../../../components/DateSelector';

const TranscriptionProblemInputs = ({ transcription, update, readOnly }) => (
  <div {...rowThirds}>
    <SearchableDropdown
      name="problemType"
      label="Transcription Problem Type"
      strongLabel
      readOnly={readOnly}
      value={transcription.problemType}
      options={[
        {
          label: '',
          value: null
        },
        {
          label: 'No audio',
          value: 'No audio'
        },
        {
          label: 'Poor Audio Quality',
          value: 'Poor Audio Quality'
        },
        {
          label: 'Incomplete Hearing',
          value: 'Incomplete Hearing'
        },
        {
          label: 'Other (see notes)',
          value: 'Other (see notes)'
        }
      ]}
      onChange={(option) => update({ problemType: (option || {}).value })}
    />
    <DateSelector
      name="problemNoticeSentDate"
      label="Problem Notice Sent"
      strongLabel
      type="date"
      readOnly={readOnly || _.isEmpty(transcription.problemType)}
      value={transcription.problemNoticeSentDate}
      onChange={(problemNoticeSentDate) => update({ problemNoticeSentDate })}
    />
    <RadioField
      name="requestedRemedy"
      label="Requested Remedy"
      strongLabel
      options={[
        {
          value: '',
          displayText: 'None',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        },
        {
          value: 'Proceed without transcript',
          displayText: 'Proceeed without transcript',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        },
        {
          value: 'Proceed with partial transcript',
          displayText: 'Process with partial transcript',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        },
        {
          value: 'New hearing',
          displayText: 'New hearing',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        }
      ]}
      value={transcription.requestedRemedy || ''}
      onChange={(requestedRemedy) => update({ requestedRemedy })}
    />
  </div>
);

TranscriptionProblemInputs.propTypes = {
  transcription: PropTypes.shape({
    problemType: PropTypes.string,
    problemNoticeSentDate: PropTypes.string,
    requestedRemedy: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool
};

export default TranscriptionProblemInputs;
