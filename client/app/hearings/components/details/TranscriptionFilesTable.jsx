import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';
import { css } from 'glamor';
import _ from 'lodash';
import moment from 'moment-timezone';

import Link from '../../../components/Link';
import Table from '../../../components/Table';
import { genericRow } from './style';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { COLORS } from '../../../constants/AppConstants';
import { DownloadIcon } from '../../../components/icons/DownloadIcon';

const tableStyling = css({
  marginTop: 0,
  '& *:focus': {
    outline: 'none'
  },
  '& tr > *:first-child': {
    paddingLeft: '2.5rem'
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
    valueName: 'dateUploadAws',
    valueFunction: (rowObject) => moment(rowObject.dateUploadAws).format('MM/DD/YYYY'),
    header: 'Uploaded',
  },
  {
    align: 'left',
    valueFunction: (rowObject) => (
      <Link href={rowObject.awsLink} target="_blank">
        {rowObject.fileName}
        <DownloadIcon color={COLORS.PRIMARY} />
      </Link>
    ),
    header: 'File Link'
  },
  {
    align: 'left',
    valueName: 'fileStatus',
    header: 'Status'
  }
];

const rowClassNames = (rowObject) => `${rowObject.isEvenGroup ? 'even' : 'odd'}-row-group`;

const TranscriptionFilesTable = ({ hearing }) => {
  const [rows, setRows] = useState([]);

  // One hearing may yield multiple recordings. Format table to group associated files by recording
  const buildRowsFromRecordings = () => {
    // Flatten nested objects into nested arrays
    const recordings = _.values(hearing.transcriptionFiles).map((rec) => _.values(rec));

    return recordings.map((recording, recordingIndex) => {
      return recording.map((file, fileIndex) => {
        const fileObj = {
          ...file,
          isEvenGroup: recordingIndex % 2 === 0
        };

        if (fileIndex === 0) {
          fileObj.docketNumber = hearing.docketNumber;
          fileObj.docketName = hearing.docketName;
        }

        return fileObj;
      });
    }).flat();
  };

  useEffect(() => {
    setRows(buildRowsFromRecordings());
  }, []);

  return (
    <div {...genericRow}>
      <Table
        id="transcription-files-table"
        columns={transcriptionFileColumns}
        getKeyForRow={(index) => index}
        rowObjects={rows}
        rowClassNames={rowClassNames}
        styling={tableStyling}
        bodyStyling={bodyStyling}
      />
    </div>
  );
};

TranscriptionFilesTable.propTypes = {
  hearing: PropTypes.shape({
    transcriptionFiles: PropTypes.object,
    docketName: PropTypes.string,
    docketNumber: PropTypes.string
  })
};

export default TranscriptionFilesTable;
