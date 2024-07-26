import React from 'react';
import COPY from '../../../COPY';
import TRANSCRIPTION_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import Checkbox from '../../components/Checkbox';
import { css } from 'glamor';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import LinkToAppeal from '../components/assignHearings/LinkToAppeal';
import { renderLegacyAppealType } from '../../queue/utils';

const styles = {
  checkBoxHeaderStyles: css({
    display: 'flex',
    '& .cf-form-checkbox': {
      position: 'relative',
      bottom: '0.2em',
      left: '2px'
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
      bottom: '0.7em',
      left: '2px'
    },
  }),
  HeaderWithIconStyles: css({
    position: 'relative',
    top: '0.2em'
  }),
};

export const selectColumn = (selectFiles, selectAll, selectedFiles, transcriptionFiles) => {
  const selectedFileIds = selectedFiles ? selectedFiles.map((file) => file.id) : [];
  const selectedTransscriptionFiles =
    transcriptionFiles ? transcriptionFiles.filter((file) => selectedFileIds.includes(file.id)) : [];
  const selectAllChecked = selectedTransscriptionFiles && transcriptionFiles &&
    selectedTransscriptionFiles.length === transcriptionFiles.length ? 'selected' : '';

  return {
    header:
    (<div {...styles.checkBoxHeaderStyles}>
      <Checkbox
        ariaLabel="select all files checkbox"
        name="select-all"
        onChange={(val) => selectAll(val)}
        value={selectAllChecked}
        label=" "
      />
      <p>{COPY.TRANSCRIPTION_FILE_DISPATCH_SELECT_COLUMN_NAME}</p>
    </div>),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.anyFiltersAreSet,
    columnName: 'selectAll',
    valueName: 'Selected',
    valueFunction: (transcriptionFile) => {
      const selectedFile = selectedFiles.find((file) => file.id === transcriptionFile.id);
      const value = selectedFile && selectedFile.status === 'selected' ? 'selected' : '';
      const disabled = selectedFile && selectedFile.status === 'locked';
      const title = selectedFile && selectedFile.message ? selectedFile.message : transcriptionFile.id;

      return (
        <div {...styles.checkBoxStyles} title={title} className="select-file">
          <Checkbox
            ariaLabel="select file checkbox"
            name={`select-file-${ transcriptionFile.id}`}
            onChange={(val) => selectFiles([transcriptionFile.id], val)}
            label={' '}
            value={value}
            disabled={disabled}
          />
        </div>
      );
    }
  };
};

export const docketNumberColumn = () => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_DOCKET_NUMBER_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.anyFiltersAreSet,
    label: 'filter by docket number',
    columnName: 'docketNumber',
    valueName: 'Docket Number',
    valueFunction: (transcriptionFile) => (
      <div>
        <DocketTypeBadge name={transcriptionFile.hearingType} />
        &nbsp;
        {transcriptionFile.docketNumber}
      </div>
    )
  };
};

export const caseDetailsColumn = () => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_CASE_DETAILS_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.anyFiltersAreSet,
    label: 'filter by case details',
    columnName: 'caseDetails',
    valueName: 'Case Details',
    valueFunction: (transcriptionFile) => (
      <div>
        {transcriptionFile.externalAppealId && (
          <LinkToAppeal
            appealExternalId={transcriptionFile.externalAppealId}
            hearingDay={{}}
            regionalOffice="">
            {transcriptionFile.caseDetails}
          </LinkToAppeal>
        )}
      </div>
    )
  };
};

export const typesColumn = () => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_TYPES_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.anyFiltersAreSet,
    label: 'filter by types',
    columnName: 'Types',
    valueName: 'Types',
    valueFunction: (transcriptionFile) => (
      <div>
        {renderLegacyAppealType({
          aod: transcriptionFile.isAdvancedOnDocket,
          type: transcriptionFile.caseType
        })}
      </div>
    ),
    filterOptions: [
      { value: 'original', displayText: 'Original' },
      { value: 'AOD', displayText: 'AOD' }
    ],
    backendCanSort: true,
    getSortValue: (transcriptionFile) => transcriptionFile.types.join(', '),
  };
};

export const hearingDateColumn = () => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_DATE_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.anyFiltersAreSet,
    label: 'filter by hearing date',
    columnName: 'hearingDate',
    valueName: 'Hearing Date',
    valueFunction: (transcriptionFile) => transcriptionFile.hearingDate,
    backendCanSort: true,
    getSortValue: (transcriptionFile) => transcriptionFile.hearingDate
  };
};

export const hearingTypeColumn = () => {
  return {
    className: 'test-column-name',
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_TYPE_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.anyFiltersAreSet,
    label: 'filter by hearing type',
    columnName: 'Hearing Type',
    valueName: 'Hearing Type',
    valueFunction: (transcriptionFile) => (
      <div>
        {transcriptionFile.hearingType === 'LegacyHearing' ? 'Legacy' : 'AMA'}
      </div>
    ),
    filterOptions: [
      { value: 'Hearing', displayText: 'Hearing' },
      { value: 'LegacyHearing', displayText: 'Legacy' }
    ],
    backendCanSort: true,
    getSortValue: (transcriptionFile) => transcriptionFile.status
  };
};

export const statusColumn = () => {
  return {
    header: <p {...styles.HeaderWithIconStyles}>{COPY.TRANSCRIPTION_FILE_DISPATCH_STATUS_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.anyFiltersAreSet,
    label: 'filter by status',
    columnName: 'status',
    valueName: 'Status',
    valueFunction: (transcriptionFile) => transcriptionFile.status
  };
};
