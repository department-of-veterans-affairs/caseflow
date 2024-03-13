import PropTypes from 'prop-types';
import React from 'react';
import { Link } from 'react-router-dom';
import { css } from 'glamor';

import Table from '../../../components/Table';
import { genericRow } from './style';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { COLORS } from '../../../constants/AppConstants';
import { DownloadIcon } from '../../../components/icons/DownloadIcon';

const tableStyling = css({
  marginTop: 0,
  '& tr > *:first-child': {
    paddingLeft: '2.5rem'
  },
  '& *:focus': {
    outline: 'none'
  }
});

const bodyStyling = css({
  '& tr:first-child td': {
    paddingTop: '3rem'
  },
  '& tr.even-row-group td': {
    backgroundColor: '#F9F9F9'
  },
  '& tr.even-row-group + tr.odd-row-group td, tr.odd-row-group + tr.even-row-group td': {
    borderTop: '1px solid #D6D7D9',
    paddingTop: '3rem'
  },
  '& tr td': {
    border: '0',
    paddingTop: '0',
    paddingBottom: '3rem',
    '&:last-child': {
      fontStyle: 'italic'
    },
    '& a': {
      display: 'inline-flex',
      alignItems: 'center'
    },
    '& svg': {
      marginLeft: '1rem'
    }
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

const buildRowObjectsFromRecordings = (recordings, hearing) => {
  return recordings.map((recording, recordingIndex) => {
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

const TranscriptionFilesTable = ({ recordings, hearing }) => (
  <div {...genericRow}>
    {recordings.length > 0 && (
      <Table
        id="transcripton-files-table"
        columns={transcriptionFileColumns}
        getKeyForRow={(index) => index}
        rowObjects={buildRowObjectsFromRecordings(recordings, hearing)}
        rowClassNames={rowClassNames}
        styling={tableStyling}
        bodyStyling={bodyStyling}
      />
    )}
  </div>
);

TranscriptionFilesTable.propTypes = {
  recordings: PropTypes.arrayOf(PropTypes.object),
  hearing: PropTypes.object
};

export default TranscriptionFilesTable;
