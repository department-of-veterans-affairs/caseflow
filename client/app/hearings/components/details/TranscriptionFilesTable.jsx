import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import Link from '../../../components/Link';
import Table from '../../../components/Table';
import { genericRow } from './style';
import DocketTypeBadge from '../../../components/DocketTypeBadge';
import { COLORS } from '../../../constants/AppConstants';
import { DownloadIcon } from '../../../components/icons/DownloadIcon';

const transcriptionFileColumns = [
  {
    align: 'left',
    valueFunction: (rowObject) => rowObject.docketName && (
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
      <Link href={`/hearings/transcription_file/${rowObject.id}/download`}>
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

  // Format table to group files by docket number and style accordingly
  const buildRowsFromFileGroups = () => {
    // Flatten nested objects into nested arrays
    const fileGroups = _.values(hearing.transcriptionFiles).map((rec) => _.values(rec));

    return fileGroups.map((fileGroup, groupIndex) => {
      return fileGroup.map((file, fileIndex) => {
        return {
          ...file,
          isEvenGroup: groupIndex % 2 === 0,
          docketName: fileIndex === 0 ? file.hearingType : null,
          docketNumber: fileIndex === 0 ? file.docketNumber : null
        };
      });
    }).flat();
  };

  useEffect(() => {
    setRows(buildRowsFromFileGroups());
  }, []);

  return (
    <div {...genericRow}>
      <Table
        className="transcription-files-table"
        columns={transcriptionFileColumns}
        getKeyForRow={(index) => index}
        rowObjects={rows}
        rowClassNames={rowClassNames}
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
