import PropTypes from 'prop-types';
import React from 'react';
import { Link } from 'react-router-dom';
import { css } from 'glamor';

import Table from '../../../components/Table';
import { genericRow } from './style';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { COLORS } from '../../../constants/AppConstants';
import { DownloadIcon } from '../../../components/icons/DownloadIcon';

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

const tableStyling = css({
  marginTop: 0,
  '& tr > *:first-child': {
    paddingLeft: '2.5rem'
  }
});

const bodyStyling = css({
  '& tr.even-row-group td': {
    backgroundColor: '#F9F9F9'
  },
  '& tr td': {
    border: '0'
  },
  '& tr.even-row-group + tr.odd-row-group td, tr.odd-row-group + tr.even-row-group td': {
    borderTop: '1px solid #D6D7D9'
  },
  '& tr td a': {
    display: 'inline-flex',
    alignItems: 'center'
  },
  '& tr td svg': {
    marginLeft: '1rem'
  },
  '& tr td:last-child': {
    fontStyle: 'italic'
  }
});

const transcriptionFileColumns = [
  {
    align: 'left',
    valueFunction: (rowObject) => (
      <span>
        <DocketTypeBadge name={rowObject.docketName} number={rowObject.docketNumber} />
        {rowObject.docketNumber}
      </span>
    ),
    header: 'Docket(s)'
  },
  {
    align: 'left',
    valueName: 'dateUploaded',
    header: 'Uploaded',
  },
  {
    align: 'left',
    valueFunction: (rowObject) => (
      <Link to="/">
        {rowObject.fileName}
        <DownloadIcon color={COLORS.PRIMARY} />
      </Link>
    ),
    header: 'File Link'
  },
  {
    align: 'left',
    valueName: 'status',
    header: 'Status'
  }
];

const buildRowObjectsFromRecordings = (hearing) => {
  // TO-DO: Replace hard-coded recordings with props
  return RECORDINGS.map((recording, recordingIndex) => {
    return recording.files.map((file, fileIndex) => {
      const fileObj = {
        ...file,
        isEvenGroup: recordingIndex % 2 === 0
      };

      if (fileIndex === 0) {
        fileObj.docketNumber = recording.docketNumber;
        fileObj.docketName = hearing.docketName;
      }

      return fileObj;
    });
  }).flat();
};

const rowClassNames = (rowObject) => `${rowObject.isEvenGroup ? 'even' : 'odd'}-row-group`;

const TranscriptionFilesTable = ({ hearing }) => (
  <div {...genericRow}>
    <Table
      id="transcripton-files-table"
      columns={transcriptionFileColumns}
      getKeyForRow={(index) => index}
      rowObjects={buildRowObjectsFromRecordings(hearing)}
      rowClassNames={rowClassNames}
      styling={tableStyling}
      bodyStyling={bodyStyling}
    />
  </div>
);

TranscriptionFilesTable.propTypes = {
  recordings: PropTypes.arrayOf(PropTypes.object),
  hearing: PropTypes.object
};

export default TranscriptionFilesTable;
