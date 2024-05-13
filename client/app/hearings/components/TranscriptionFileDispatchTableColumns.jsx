import React from 'react';
import COPY from '../../../COPY';
import TRANSCRIPTION_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import Checkbox from '../../components/Checkbox';
import { css } from 'glamor';

const styles = {
  checkBoxHeaderStyles: css({
    display: 'flex',
    '& .cf-form-checkbox': {
      position: 'relative',
      bottom: '0.2em',
    },
    '& p': {
      marginBottom: '1em',
      marginLeft: '0.2em'
    }
  }),
  checkBoxStyles: css({
    '& .cf-form-checkboxes': {
      marginBottom: '0rem'
    },
    '& .checkbox-wrapper-undefined': {
      marginTop: '1em'
    },
    '& .cf-form-checkbox': {
      bottom: '0.7em'
    },
  }),
  HeaderWithIconStyles: css({
    position: 'relative',
    top: '0.2em'
  }),
};

export const selectColumn = (transcriptionFiles) => {
  return {
    header:
    (<div {...styles.checkBoxHeaderStyles}>
      <Checkbox />
      <p>{COPY.TRANSCRIPTION_FILE_DISPATCH_SELECT_COLUMN_NAME}</p>
    </div>),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.filterable,
    columnName: 'selectAll',
    tableData: transcriptionFiles,
    valueName: 'Selected',
    valueFunction: () => <div {...styles.checkBoxStyles}><Checkbox /></div>
  };
};

export const docketNumberColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_DOCKET_NUMBER_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.filterable,
    columnName: 'docketNumber',
    tableData: transcriptionFiles,
    valueName: 'Docket Number',
    valueFunction: (transcriptionFile) => transcriptionFile.docketNumber
  };
};

export const caseDetailsColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_CASE_DETAILS_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.filterable,
    columnName: 'caseDetails',
    tableData: transcriptionFiles,
    valueName: 'Case Details',
    valueFunction: (transcriptionFile) => transcriptionFile.caseDetails
  };
};

export const typesColumn = (transcriptionFiles) => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_TYPES_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.filterable,
    columnName: 'type',
    tableData: transcriptionFiles,
    valueName: 'Type',
    valueFunction: (transcriptionFile) => transcriptionFile.type,
    getSortValue: (transcriptionFile) => transcriptionFile.type
  };
};

export const hearingDateColumn = (transcriptionFiles) => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_DATE_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.filterable,
    columnName: 'hearingDate',
    tableData: transcriptionFiles,
    valueName: 'Hearing Date',
    valueFunction: (transcriptionFile) => transcriptionFile.hearingDate,
    getSortValue: (transcriptionFile) => transcriptionFile.hearingDate
  };
};

export const hearingTypeColumn = (transcriptionFiles) => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_TYPE_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.filterable,
    columnName: 'hearingType',
    tableData: transcriptionFiles,
    valueName: 'Hearing Type',
    valueFunction: (transcriptionFile) => transcriptionFile.hearingType,
  };
};

export const statusColumn = (transcriptionFiles) => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_STATUS_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.filterable,
    columnName: 'status',
    tableData: transcriptionFiles,
    valueName: 'Status',
    valueFunction: (transcriptionFile) => transcriptionFile.status
  };
};
