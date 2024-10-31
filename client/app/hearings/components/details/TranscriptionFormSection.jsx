import PropTypes from 'prop-types';
import React from 'react';

import { ContentSection } from '../../../components/ContentSection';
import TranscriptionDetailsInputs from './TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './TranscriptionProblemInputs';
import TranscriptionRequestInputs from './TranscriptionRequestInputs';
import TranscriptionFilesTable from './TranscriptionFilesTable';
import { genericRow } from './style';

export const TranscriptionFormSection = (
  { hearing, transcription, readOnly, update, isLegacy }
) => (
  <ContentSection header="Transcription Details">
    {/* If Legacy Hearing and conference provider Webex, only render Transcription Files table */}
    {!isLegacy && (
      <>
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
        {hearing.conferenceProvider === 'webex' && <div className="cf-help-divider" />}
      </>
    )}

    {/* If conference provider not Webex, do not render Transcriptoin Files table */}
    {hearing.conferenceProvider === 'webex' && (
      <>
        <h3 {...(isLegacy && { ...genericRow })}>Transcription Files</h3>
        <TranscriptionFilesTable
          hearing={hearing}
        />
      </>
    )}
  </ContentSection>
);

TranscriptionFormSection.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  transcription: PropTypes.object,
  isLegacy: PropTypes.bool,
  isWebex: PropTypes.bool
};
