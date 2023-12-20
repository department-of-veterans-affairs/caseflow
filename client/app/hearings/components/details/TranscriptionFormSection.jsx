import PropTypes from 'prop-types';
import React from 'react';

import { ContentSection } from '../../../components/ContentSection';
import TranscriptionDetailsInputs from './TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './TranscriptionProblemInputs';
import TranscriptionRequestInputs from './TranscriptionRequestInputs';

export const TranscriptionFormSection = (
  { hearing, transcription, readOnly, update }
) => (
  <ContentSection header="Transcription Details">
    <TranscriptionDetailsInputs
      title="Transcription Details"
      transcription={transcription}
      update={(values) => update('transcription', values)}
      readOnly={readOnly}
    />
    <div className="cf-help-divider" />

    <h3>Transcription Problem</h3>
    <TranscriptionProblemInputs
      transcription={transcription}
      update={(values) => update('transcription', values)}
      readOnly={readOnly}
    />
    <div className="cf-help-divider" />

    <h3>Transcription Request</h3>
    <TranscriptionRequestInputs
      hearing={hearing}
      update={(values) => update('hearing', values)}
      readOnly={readOnly}
    />
  </ContentSection>
);

TranscriptionFormSection.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  transcription: PropTypes.object
};
