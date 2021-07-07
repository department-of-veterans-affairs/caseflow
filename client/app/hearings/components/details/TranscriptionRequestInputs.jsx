import React from 'react';
import PropTypes from 'prop-types';

import { rowThirds } from './style';
import DateSelector from '../../../components/DateSelector';
import Checkbox from '../../../components/Checkbox';

const TranscriptionRequestInputs = ({ hearing, update, readOnly }) => (
  <div {...rowThirds}>
    <div>
      <strong>Copy Requested by Appellant/Rep</strong>
      <Checkbox
        name="copyRequested"
        label="Yes, Transcript Requested"
        value={hearing?.transcriptRequested || false}
        disabled={readOnly}
        onChange={(transcriptRequested) => update({ transcriptRequested })}
      />
    </div>
    <DateSelector
      name="copySentDate"
      label="Copy Sent to Appellant/Rep"
      strongLabel
      readOnly={readOnly}
      value={hearing?.transcriptSentDate}
      onChange={(transcriptSentDate) => update({ transcriptSentDate })}
    />
    <div />
  </div>
);

TranscriptionRequestInputs.propTypes = {
  hearing: PropTypes.shape({
    transcriptRequested: PropTypes.bool,
    transcriptSentDate: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool
};

export default TranscriptionRequestInputs;
