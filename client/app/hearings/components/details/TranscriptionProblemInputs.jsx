import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { getOptionsFromObject } from '../../utils';
import { rowThirds } from './style';
import DateSelector from '../../../components/DateSelector';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import TRANSCRIPTION_PROBLEM_TYPES from
  '../../../../constants/TRANSCRIPTION_PROBLEM_TYPES';
import TRANSCRIPTION_REQUESTED_REMEDIES from
  '../../../../constants/TRANSCRIPTION_REQUESTED_REMEDIES';

const TRANSCRIPTION_PROBLEM_OPTIONS = getOptionsFromObject(
  TRANSCRIPTION_PROBLEM_TYPES,
  {
    label: 'None',
    value: null
  },
  (value) => ({ label: value, value })
);

const TRANSCRIPTION_REMEDIES_OPTIONS = getOptionsFromObject(
  TRANSCRIPTION_REQUESTED_REMEDIES,
  {
    displayText: 'None',
    value: ''
  },
  (value) => ({ displayText: value, value })
);

const TranscriptionProblemInputs = ({ transcription, update, readOnly }) => (
  <div {...rowThirds}>
    <SearchableDropdown
      name="problemType"
      label="Transcription Problem Type"
      strongLabel
      readOnly={readOnly}
      value={transcription?.problemType}
      options={TRANSCRIPTION_PROBLEM_OPTIONS}
      onChange={(option) => update({ problemType: (option || {}).value })}
    />
    <DateSelector
      name="problemNoticeSentDate"
      label="Problem Notice Sent"
      strongLabel
      readOnly={readOnly || _.isEmpty(transcription?.problemType)}
      value={transcription?.problemNoticeSentDate}
      onChange={(problemNoticeSentDate) => update({ problemNoticeSentDate })}
    />
    <RadioField
      name="requestedRemedy"
      label="Requested Remedy"
      strongLabel
      options={
        _.map(
          TRANSCRIPTION_REMEDIES_OPTIONS,
          (entry) => (
            _.extend(entry, { disabled: readOnly || _.isEmpty(transcription?.problemType) })
          )
        )
      }
      value={transcription?.requestedRemedy || ''}
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
