import PropTypes from 'prop-types';
import React from 'react';

import { ContentSection } from '../../../components/ContentSection';
import {
  UPDATE_HEARING_DETAILS,
  UPDATE_TRANSCRIPTION,
} from '../../contexts/HearingsFormContext';
import TranscriptionDetailsInputs from './TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './TranscriptionProblemInputs';
import TranscriptionRequestInputs from './TranscriptionRequestInputs';

export const TranscriptionFormSection = (
  { hearing, transcription, readOnly, dispatch }
) => (
  <ContentSection header="Transcription Details">
    <TranscriptionDetailsInputs
      title="Transcription Details"
      transcription={transcription}
      update={(values) => dispatch({ type: UPDATE_TRANSCRIPTION, payload: values })}
      readOnly={readOnly}
    />
    <div className="cf-help-divider" />

    <h3>Transcription Problem</h3>
    <TranscriptionProblemInputs
      transcription={transcription}
      update={(values) => dispatch({ type: UPDATE_TRANSCRIPTION, payload: values })}
      readOnly={readOnly}
    />
    <div className="cf-help-divider" />

    <h3>Transcription Request</h3>
    <TranscriptionRequestInputs
      hearing={hearing}
      update={(values) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: values })}
      readOnly={readOnly}
    />
  </ContentSection>
);

TranscriptionFormSection.propTypes = {
  dispatch: PropTypes.func,
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  transcription: PropTypes.object
};
