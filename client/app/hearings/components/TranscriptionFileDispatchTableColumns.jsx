/* eslint-disable max-lines */

import React from 'react';
import COPY from '../../../COPY';
import TRANSCRIPTION_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import Checkbox from '../../components/Checkbox';
import { css } from 'glamor';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import LinkToAppeal from '../components/assignHearings/LinkToAppeal';
import { renderLegacyAppealType } from '../../queue/utils';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import { COLORS, ICON_SIZES } from '../../constants/AppConstants';
import { Link } from 'react-router-dom';

const styles = {
  checkBoxHeader: css({
    display: 'flex',
    '& .cf-form-checkbox': {
      position: 'relative',
      bottom: '0.2em',
      left: '2px',
    },
    '& p': {
      marginBottom: '1em',
      marginLeft: '0.2em',
    },
  }),
  checkBox: css({
    '& .cf-form-checkboxes': {
      marginBottom: '0rem',
    },
    '& .checkbox-wrapper-undefined': {
      marginTop: '1em',
    },
    '& .cf-form-checkbox': {
      bottom: '0.7em',
      left: '2px',
    },
  }),
  headerWithIcon: css({
    position: 'relative',
    top: '0.2em',
  }),
  link: {
    cursor: 'pointer',
  },
  unassign: {
    cursor: 'pointer',
    margin: '0 3em',
  },
  error: {
    color: '#E60000',
  },
  linkIcon: {
    position: 'relative',
    marginLeft: '0.4em',
    top: '3px',
  },
  workOrderLink: {
    cursor: 'pointer',
    whiteSpace: 'nowrap',
    paddingRight: '1.3em',
    position: 'relative',
  },
  workOrderLinkIcon: {
    position: 'absolute',
    top: '-0.2em',
    right: 0,
  },
  contractor: {
    maxWidth: '150px',
  },
};

export const selectColumn = (
  selectFiles,
  selectAll,
  selectedFiles,
  transcriptionFiles
) => {
  const selectedFileIds = selectedFiles ?
    selectedFiles.map((file) => file.id) :
    [];
  const selectedTransscriptionFiles = transcriptionFiles ?
    transcriptionFiles.filter((file) => selectedFileIds.includes(file.id)) :
    [];
  const selectAllChecked =
    selectedTransscriptionFiles &&
    transcriptionFiles &&
    selectedTransscriptionFiles.length === transcriptionFiles.length ?
      'selected' :
      '';

  return {
    header: (
      <div {...styles.checkBoxHeader}>
        <Checkbox
          ariaLabel="select all files checkbox"
          name="select-all"
          onChange={(val) => selectAll(val)}
          value={selectAllChecked}
          label=" "
        />
        <p>{COPY.TRANSCRIPTION_FILE_DISPATCH_SELECT_COLUMN_NAME}</p>
      </div>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.SELECT_ALL.anyFiltersAreSet,
    valueFunction: (row) => {
      const selectedFile = selectedFiles.find((file) => file.id === row.id);
      const value =
        selectedFile && selectedFile.status === 'selected' ? 'selected' : '';
      const disabled = selectedFile && selectedFile.status === 'locked';
      const title =
        selectedFile && selectedFile.message ? selectedFile.message : row.id;

      return (
        <div {...styles.checkBox} title={title} className="select-file">
          <Checkbox
            ariaLabel="select file checkbox"
            name={`select-file-${row.id}`}
            onChange={(val) => selectFiles([row.id], val)}
            label={' '}
            value={value}
            disabled={disabled}
          />
        </div>
      );
    },
  };
};

export const docketNumberColumn = () => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_DOCKET_NUMBER_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.name,
    enableFilter:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DOCKET_NUMBER.anyFiltersAreSet,
    valueFunction: (row) => (
      <div>
        <DocketTypeBadge name={row.hearingType} number={row.id} />
        &nbsp;
        {row.docketNumber}
      </div>
    ),
  };
};

export const caseDetailsColumn = () => {
  return {
    header: COPY.TRANSCRIPTION_FILE_DISPATCH_CASE_DETAILS_COLUMN_NAME,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CASE_DETAILS.anyFiltersAreSet,
    valueFunction: (row) => (
      <div>
        {row.externalAppealId && (
          <LinkToAppeal
            id={row.id}
            appealExternalId={row.externalAppealId}
            hearingDay={{}}
            regionalOffice=""
          >
            {row.caseDetails}
          </LinkToAppeal>
        )}
      </div>
    ),
  };
};

export const typesColumn = () => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_TYPES_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.TYPES.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_TYPES_COLUMN_NAME,
    label: 'types filter',
    valueFunction: (row) => (
      <div>
        {renderLegacyAppealType({
          aod: row.isAdvancedOnDocket,
          type: row.caseType,
        })}
      </div>
    ),
    filterOptions: [
      { value: 'original', displayText: 'Original' },
      { value: 'AOD', displayText: 'AOD' },
    ],
    backendCanSort: true,
    getSortValue: (row) => row.types.join(', '),
  };
};

export const hearingDateColumn = () => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_DATE_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_DATE.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_DATE_COLUMN_NAME,
    label: 'hearing date filter',
    valueFunction: (row) => row.hearingDate,
    backendCanSort: true,
    getSortValue: (row) => row.hearingDate,
    filterType: 'date-picker',
    filterSettings: {
      buttons: false,
      position: 'right',
    },
  };
};

export const hearingTypeColumn = () => {
  return {
    className: 'test-column-name',
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_TYPE_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.HEARING_TYPE.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_TYPE_COLUMN_NAME,
    label: 'hearing types filter',
    valueFunction: (row) => (
      <div>{row.hearingType === 'LegacyHearing' ? 'Legacy' : 'AMA'}</div>
    ),
    filterOptions: [
      { value: 'Hearing', displayText: 'AMA' },
      { value: 'LegacyHearing', displayText: 'Legacy' },
    ],
    backendCanSort: true,
    getSortValue: (row) => row.status,
  };
};

export const workOrderColumn = () => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_WORK_ORDER_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.WORK_ORDER.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.WORK_ORDER.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.WORK_ORDER.anyFiltersAreSet,
    valueFunction: (row) => (
      <div>
        <Link
          to={`/transcription_work_order/display_wo_summary/?taskNumber=${
            row.workOrder
          }`}
          target="_blank"
          style={styles.workOrderLink}
        >
          #{row.workOrder}
          <span style={styles.workOrderLinkIcon}>
            <ExternalLinkIcon color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
          </span>
        </Link>
      </div>
    ),
    backendCanSort: true,
    getSortValue: (row) => row.status,
  };
};

export const itemsColumn = (openModal) => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_ITEMS_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.ITEMS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.ITEMS.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.ITEMS.anyFiltersAreSet,
    valueFunction: (row) => (
      <div>
        <a
          style={styles.link}
          onClick={() =>
            openModal({ type: 'highlights', workOrder: row.workOrder })
          }
        >
          {row.items} item{row.items === 1 ? '' : 's'}
        </a>
      </div>
    ),
  };
};

export const dateSentColumn = () => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_DATE_SENT_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DATE_SENT.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DATE_SENT.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.DATE_SENT.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_DATE_SENT_COLUMN_NAME,
    label: 'date sent filter',
    valueFunction: (row) => row.dateSent,
    backendCanSort: true,
    getSortValue: (row) => row.dateSent,
    filterType: 'date-picker',
    filterSettings: {
      buttons: false,
      position: 'right',
    },
  };
};

export const returnDateColumn = () => {
  return {
    header: <p {...styles.headerWithIcon}>{COPY.TRANSCRIPTION_FILE_DISPATCH_RETURN_DATE_COLUMN_NAME}</p>,
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.RETURN_DATE.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.RETURN_DATE.filterable,
    anyFiltersAreSet: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.RETURN_DATE.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_RETURN_DATE_COLUMN_NAME,
    label: 'return date filter',
    valueFunction: (row) => row.returnDate || '-',
    backendCanSort: true,
    getSortValue: (row) => row.returnDate,
    filterType: 'date-picker',
    filterSettings: {
      buttons: false,
      position: 'right'
    }
  };
};

export const expectedReturnDateColumn = () => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_EXPECTED_RETURN_DATE_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.EXPECTED_RETURN_DATE.name,
    enableFilter:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.EXPECTED_RETURN_DATE.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.EXPECTED_RETURN_DATE.anyFiltersAreSet,
    columnName:
      COPY.TRANSCRIPTION_FILE_DISPATCH_EXPECTED_RETURN_DATE_COLUMN_NAME,
    label: 'expected return date filter',
    valueFunction: (row) => row.expectedReturnDate,
    backendCanSort: true,
    getSortValue: (row) => row.expectedReturnDate,
    filterType: 'date-picker',
    filterSettings: {
      buttons: false,
      position: 'right',
    },
  };
};

export const uploadDateColumn = () => {
  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_UPLOAD_DATE_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.UPLOAD_DATE.name,
    enableFilter:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.UPLOAD_DATE.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.UPLOAD_DATE.anyFiltersAreSet,
    columnName:
      COPY.TRANSCRIPTION_FILE_DISPATCH_UPLOAD_DATE_COLUMN_NAME,
    label: 'upload date filter',
    valueFunction: (row) => row.uploadDate,
    backendCanSort: true,
    getSortValue: (row) => row.uploadDate,
    filterType: 'date-picker',
    filterSettings: {
      buttons: false,
      position: 'right',
    },
  };
};

export const contractorColumn = (contractors) => {
  const filterOptions = contractors ?
    contractors.map((contractor) => ({
      value: contractor.name,
      displayText: contractor.name,
    })) :
    [];

  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_CONTRACTOR_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CONTRACTOR.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CONTRACTOR.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.CONTRACTOR.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_CONTRACTOR_COLUMN_NAME,
    label: 'contractor filter',
    filterOptions,
    valueFunction: (row) => (
      <div style={styles.contractor}>{row.contractor}</div>
    ),
    backendCanSort: true,
    getSortValue: (row) => row.expectedReturnDate,
  };
};

export const statusColumn = (currentTab) => {
  let filterOptions;

  if (currentTab === COPY.TRANSCRIPTION_DISPATCH_ASSIGNED_TAB) {
    filterOptions = [
      {
        value: COPY.TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION,
        displayText: COPY.TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION,
      },
      {
        value: COPY.TRANSCRIPTION_STATUS_BOX_UPLOAD_SUCCESS_FILTER_OPTION_VALUE,
        displayText: COPY.TRANSCRIPTION_STATUS_SENT_FILTER_OPTION,
      }
    ];
  } else if (currentTab === COPY.TRANSCRIPTION_DISPATCH_COMPLETED_TAB) {
    filterOptions = [
      {
        value: COPY.TRANSCRIPTION_STATUS_AWS_UPLOAD_SUCCESS_FILTER_OPTION_VALUE,
        displayText: COPY.TRANSCRIPTION_STATUS_COMPLETED_FILTER_OPTION,
      },
      {
        value: COPY.TRANSCRIPTION_STATUS_RETRIEVAL_FAILURE_FILTER_VALUE,
        displayText: COPY.TRANSCRIPTION_STATUS_RETRIEVAL_FAILURE_FILTER_OPTION,
      },
      {
        value: COPY.TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION,
        displayText: COPY.TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION,
      },
    ];
  } else if (currentTab === 'All') {
    filterOptions = [
      {
        value: COPY.TRANSCRIPTION_STATUS_COMPLETED_FILTER_OPTION,
        displayText: COPY.TRANSCRIPTION_STATUS_COMPLETED_FILTER_OPTION,
      },
      {
        value: COPY.TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION,
        displayText: COPY.TRANSCRIPTION_STATUS_OVERDUE_FILTER_OPTION,
      },
      {
        value: COPY.TRANSCRIPTION_STATUS_RETRIEVAL_FAILURE_FILTER_VALUE,
        displayText: COPY.TRANSCRIPTION_STATUS_RETRIEVAL_FAILURE_FILTER_OPTION,
      },
      {
        value: COPY.TRANSCRIPTION_STATUS_BOX_UPLOAD_SUCCESS_FILTER_OPTION_VALUE,
        displayText: COPY.TRANSCRIPTION_STATUS_SENT_FILTER_OPTION,
      },
    ];
  } else {
    filterOptions = [];
  }

  return {
    header: (
      <p {...styles.headerWithIcon}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_STATUS_COLUMN_NAME}
      </p>
    ),
    name: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.name,
    enableFilter: TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.filterable,
    anyFiltersAreSet:
      TRANSCRIPTION_DISPATCH_CONFIG.COLUMNS.STATUS.anyFiltersAreSet,
    columnName: COPY.TRANSCRIPTION_FILE_DISPATCH_STATUS_COLUMN_NAME,
    label: 'status filter',
    filterOptions,
    valueFunction: (row) => {
      let status = currentTab === COPY.TRANSCRIPTION_DISPATCH_COMPLETED_TAB || currentTab === 'All' ?
        row.fileStatus : row.status;
      let displayStatus = status;

      if (status === 'Successful upload (AWS)') {
        displayStatus = 'Completed';
      } else if (status === 'Successful Upload (BOX)') {
        displayStatus = 'Sent';
      } else if (status === 'Failed Retrieval (BOX)') {
        displayStatus = 'Retrieval Failure';
      }

      return (
        <div
          style={
            row.status === 'Overdue' || row.status === 'Failed Retrieval (BOX)' ?
              styles.error :
              {}
          }
        >
          {displayStatus}
        </div>
      );
    },
    backendCanSort: true,
    getSortValue: (row) => row.status,
  };
};

export const unassignColumn = (unassignPackage) => {
  return {
    valueFunction: (row) => (
      <div>
        <a
          style={styles.unassign}
          onClick={() => unassignPackage(row.workOrder)}
        >
          Unassign
        </a>
      </div>
    ),
  };
};

