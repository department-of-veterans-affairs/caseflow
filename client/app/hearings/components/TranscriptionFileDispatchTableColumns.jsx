import React from 'react';
import COPY from '../../../COPY';
import TRANSCRIPTION_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import Checkbox from '../../components/Checkbox';

export const selectColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_SELECT_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.filterable,
    columnName: 'select_all',
    tableData: transcriptionFiles,
    valueName: 'Selected',
    valueFunction: () => <Checkbox />
  };
};

export const docketNumberColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_DOCKET_NUMBER_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.filterable,
    columnName: 'docket_number',
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
    columnName: 'case_details',
    tableData: transcriptionFiles,
    valueName: 'Case Details',
    valueFunction: (transcriptionFile) => transcriptionFile.case_details
  };
};

export const typesColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_TYPES_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.filterable,
    columnName: 'type',
    tableData: transcriptionFiles,
    valueName: 'Type',
    valueFunction: (transcriptionFile) => transcriptionFile.type
  };
};

export const hearingDateColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_DATE_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.filterable,
    columnName: 'hearing_date',
    tableData: transcriptionFiles,
    valueName: 'Hearing Date',
    valueFunction: (transcriptionFile) => transcriptionFile.hearing_date
  };
};

export const hearingTypeColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_TYPE_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.filterable,
    columnName: 'hearing_type',
    tableData: transcriptionFiles,
    valueName: 'Hearing Type',
    valueFunction: (transcriptionFile) => transcriptionFile.hearing_type
  };
};

export const statusColumn = (transcriptionFiles) => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_STATUS_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.filterable,
    columnName: 'status',
    tableData: transcriptionFiles,
    valueName: 'Status',
    valueFunction: (transcriptionFile) => transcriptionFile.status
  };
};
