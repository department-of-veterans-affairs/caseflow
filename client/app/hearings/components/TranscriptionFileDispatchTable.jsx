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

export const TranscriptionFileDispatchTable = () => {
  const [transcriptionFiles, setTranscriptionFiles] = useState([]);

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
    <QueueTable
      columns={columnsFromConfig(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
      rowObjects={transcriptionFiles}
      enablePagination
      casesPerPage={15}
      sortColName="Hearing Date"
      defaultSort={{
        sortColName: 'hearingDateColumn',
        sortAscending: true
      }}
    />
  );
};
