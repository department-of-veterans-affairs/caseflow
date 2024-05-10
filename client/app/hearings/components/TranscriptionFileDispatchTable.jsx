import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import QueueTable from '../../queue/QueueTable';
import TRANSCRIPTION_FILE_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import
{ selectColumn,
  docketNumberColumn,
  caseDetailsColumn,
  typesColumn,
  hearingDateColumn,
  hearingTypeColumn,
  statusColumn } from './TranscriptionFileDispatchTableColumns';
import { css } from 'glamor';

const dateSelectorStyles = css({
  '& .cf-form-textinput': {
    border: 'none',
    width: '44px'
  },
  '& .cf-form-textinput:focus': {
    outline: 'none'
  }
});

export const TranscriptionFileDispatchTable = () => {
  const items = [{
    docketNumber: "1234-56789",
    caseDetails: "John Smith (1000001)",
    type: "Original",
    hearingDate: "5/10/2024",
    hearingType: "AMA",
    status: "Unassigned"
  },
  {
    docketNumber: "1234-56789",
    caseDetails: "Jane Smith (2000001)",
    type: "AOD",
    hearingDate: "5/12/2024",
    hearingType: "Legacy",
    status: "Unassigned"
  }
  ]
  const data = [].concat(...Array(8).fill(items));
  const [transcriptionFiles, setTranscriptionFiles] = useState(data);

  const createUnassignedColumnObject = (column) => {
    const functionForColumn = {
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.name]: selectColumn(transcriptionFiles),
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(transcriptionFiles),
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.name]: caseDetailsColumn(transcriptionFiles),
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.TYPES.name]: typesColumn(transcriptionFiles),
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.name]: hearingDateColumn(transcriptionFiles),
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.name]: hearingTypeColumn(transcriptionFiles),
      [TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS.STATUS.name]: statusColumn(transcriptionFiles)
    };

    return functionForColumn[column.name];
  };

  const columnsFromConfig = (columns) => {
    return Object.values(columns).map((column) => createUnassignedColumnObject(column));
  };

  return (
    <div {...dateSelectorStyles} >
      <QueueTable
        columns={columnsFromConfig(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
        rowObjects={transcriptionFiles}
        enablePagination
        casesPerPage={15}
        // sortColName="Hearing Date"
        // defaultSort={{
        //   sortColName: 'hearingDateColumn',
        //   sortAscending: true
        // }}
      />
    </div>
  );
};
