import PropTypes from 'prop-types';
import React from 'react';

import { ContentSection } from '../../../components/ContentSection';
import TranscriptionDetailsInputs from './TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './TranscriptionProblemInputs';
import TranscriptionRequestInputs from './TranscriptionRequestInputs';
import TranscriptionFilesTable from './TranscriptionFilesTable';
import { genericRow } from './style';

// TO-DO: Replace hard-coded recordings
const RECORDINGS = [
  {
    hearingType: 'Hearing',
    docketNumber: '230808-800',
    files: [
      {
        fileName: 'ROSELIA_TURNER0510.MP4',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510.vtt',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510.MP3',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510.rtf',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      }
    ]
  },
  {
    hearingType: 'Hearing',
    docketNumber: '230808-800',
    files: [
      {
        fileName: 'ROSELIA_TURNER0510-2.MP4',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.vtt',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.MP3',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.rtf',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      }
    ]
  },
  {
    hearingType: 'Hearing',
    docketNumber: '230808-800',
    files: [
      {
        fileName: 'ROSELIA_TURNER0510-2.MP4',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.vtt',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.MP3',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.rtf',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      }
    ]
  },
  {
    hearingType: 'Hearing',
    docketNumber: '230808-800',
    files: [
      {
        fileName: 'ROSELIA_TURNER0510-2.MP4',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.vtt',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.MP3',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      },
      {
        fileName: 'ROSELIA_TURNER0510-2.rtf',
        status: 'Successful upload (AWS)',
        dateUploaded: '08/11/22'
      }
    ]
  }
];

export const TranscriptionFormSection = (
  { hearing, transcription, readOnly, update, isLegacy }
) => (
  <ContentSection header="Transcription Details">
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
        <div className="cf-help-divider" />
      </>
    )}

    <h3 {...(isLegacy && { ...genericRow })}>Transcription Files</h3>
    <TranscriptionFilesTable
      recordings={RECORDINGS}
      hearing={hearing}
    />
  </ContentSection>
);

TranscriptionFormSection.propTypes = {
  update: PropTypes.func,
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  transcription: PropTypes.object,
  isLegacy: PropTypes.bool
};
