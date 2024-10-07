import React from 'react';
import COPY from '../../../COPY';
import Link from '../../components/Link';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import { COLORS, ICON_SIZES } from '../../constants/AppConstants';
import SearchBar from '../../components/SearchBar';
import Button from '../../components/Button';
import { TranscriptionFileDispatchTable } from './TranscriptionFileDispatchTable';
import { css } from 'glamor';
import TRANSCRIPTION_FILE_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import { sprintf } from 'sprintf-js';

const styles = {
  tabColumns: {
    float: 'left',
    width: '100%'
  },
  tabColumn: {
    float: 'left',
    width: '50%'
  },
  settingsLink: {
    textAlign: 'right',
    marginBottom: '2.5em'
  },
  linkStyles: {
    display: 'inline-flex',
    fontSize: '15px',
    cursor: 'pointer',
  },
  linkIconStyles: {
    marginLeft: '0.2em',
    position: 'relative',
    top: '2px'
  },
  filesHeading: {
    margin: '1em 0 1em 0'
  },
  fileSelect: {
    margin: '2.65em 0 2em 0'
  },
  searchBar: css({
    marginBottom: '4em',
    '& input': {
      width: '100% !important',
      maxWidth: '100%',
      marginTop: '0.5em'
    },
    '& .usa-search-big': {
      maxWidth: '100%',
      width: '550px'
    }
  }),
  tableWrapper: {
    clear: 'both',
  }
};

/**
 * Configuring a table for the unassigned tab
 * @param {object} column - The json object that has all the columns listed with required attributes
 * @returns An object for configuring the table
 */
export const unassignedColumns = (columns) => {
  const { SELECT_ALL, DOCKET_NUMBER, CASE_DETAILS, TYPES, HEARING_DATE, HEARING_TYPE } = columns;

  return { SELECT_ALL, DOCKET_NUMBER, CASE_DETAILS, TYPES, HEARING_DATE, HEARING_TYPE };
};

/**
 * Configuring a table for the unassigned tab
 * @param {object} column - The json object that has all the columns listed with required attributes
 * @returns An object for configuring the table
 */
export const assignedColumns = (columns) => {
  const { WORK_ORDER, ITEMS, DATE_SENT, EXPECTED_RETURN_DATE, CONTRACTOR, STATUS, UNASSIGN } = columns;

  return { WORK_ORDER, ITEMS, DATE_SENT, EXPECTED_RETURN_DATE, CONTRACTOR, STATUS, UNASSIGN };
};

/**
 * Configuring a table for the completed tab
 * @param {object} column - The json object that has all the columns listed with required attributes
 * @returns An object for configuring the table
 */
export const completedColumns = (columns) => {
  const { DOCKET_NUMBER, TYPES, HEARING_DATE, EXPECTED_RETURN_DATE, RETURN_DATE, CONTRACTOR, STATUS, WORK_ORDER } = columns;

  return { DOCKET_NUMBER, TYPES, HEARING_DATE, EXPECTED_RETURN_DATE, RETURN_DATE, CONTRACTOR, STATUS, WORK_ORDER };
};

/**
 * A mini template component for transcription settings link
 */
const TranscriptionSettingsLink = () => (
  <div style={styles.settingsLink}>
    <Link linkStyling to="/find_by_contractor">
      <span style={styles.linkStyles}>
        {COPY.TRANSCRIPTION_FILE_DISPATCH_LINK}
        <span style={styles.linkIconStyles}>
          <ExternalLinkIcon style={styles.linkIconStyles} color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
        </span>
      </span>
    </Link>
  </div>
);

// This maps the component to render for each tab
export const tabConfig = (openModal, selectFilesForPackage, files) => [
  {
    label: COPY.CASE_LIST_TABLE_UNASSIGNED_LABEL,
    page: <>
      <div style={styles.tabColumns}>
        <div style={styles.tabColumn}>
          <div>{COPY.TRANSCRIPTION_FILE_DISPATCH_UNASSIGNED_TAB_DESCRIPTION}</div>
          <div style={styles.fileSelect}>
            <div>{COPY.TRANSCRIPTION_FILE_DISPATCH_UNASSIGNED_TAB_PROMPT}</div>
            <h2 style={styles.filesHeading}>
              {sprintf(COPY.TRANSCRIPTION_FILE_DISPATCH_FILE_SELECTED, files, files === 1 ? '' : 's')}
            </h2>
            <div className="button-row" style={styles.buttonStyles}>
              <Button disabled={files === 0} onClick={() => openModal({ type: 'package' })}>Package files</Button>
              <Button linkStyling>Cancel</Button>
            </div>
          </div>
        </div>
        <div style={styles.tabColumn}>
          <TranscriptionSettingsLink />
          <div {...styles.searchBar} >
            <SearchBar
              placeholder={COPY.TRANSCRIPTION_FILE_DISPATCH_TYPE}
              size="big"
              id="transcription-table-search"
              isSearchAhead
              title={COPY.TRANSCRIPTION_FILE_DISPATCH_UNASSIGNED_TAB_SEARCH}
            />
          </div>
        </div>
      </div>
      <div style={styles.tableWrapper}>
        <TranscriptionFileDispatchTable
          columns={unassignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
          statusFilter={['Unassigned']}
          selectFilesForPackage={selectFilesForPackage}
        />
      </div>
    </>
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_ASSIGNED_TAB,
    page: <>
      <div style={styles.tabColumns}>
        <div style={styles.tabColumn}>
          <div>{COPY.TRANSCRIPTION_FILE_DISPATCH_ASSIGNED_TAB_DESCRIPTION}</div>
        </div>
        <div style={styles.tabColumn}>
          <div {...styles.searchBar} >
            <SearchBar
              placeholder={COPY.TRANSCRIPTION_FILE_DISPATCH_TYPE}
              size="big"
              id="transcription-table-search"
              isSearchAhead
              title={COPY.TRANSCRIPTION_FILE_DISPATCH_ASSIGNED_TAB_SEARCH}
            />
          </div>
        </div>
      </div>
      <div style={styles.tableWrapper}>
        <TranscriptionFileDispatchTable
          columns={assignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
          statusFilter={['Assigned']}
          selectFilesForPackage={selectFilesForPackage}
          openModal={openModal}
        />
      </div>
    </>
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_COMPLETED_TAB,
    page: <>
      <div style={styles.tabColumns}>
        <div style={styles.tabColumn}>
          <div>{COPY.TRANSCRIPTION_FILE_DISPATCH_COMPLETED_TAB_DESCRIPTION}</div>
        </div>
        <div style={styles.tabColumn}>
          <div {...styles.searchBar} >
            <SearchBar
              placeholder={COPY.TRANSCRIPTION_FILE_DISPATCH_TYPE}
              size="big"
              id="transcription-table-search"
              isSearchAhead
              title={COPY.TRANSCRIPTION_FILE_DISPATCH_COMPLETED_TAB_SEARCH}
            />
          </div>
        </div>
      </div>
      <div style={styles.tableWrapper}>
        <TranscriptionFileDispatchTable
          columns={completedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
          statusFilter={['Completed']}
          selectFilesForPackage={selectFilesForPackage}
        />
      </div>
    </>
  },
  {
    label: COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB,
    page: <>
      <div style={styles.tabColumns}>
        <div style={styles.tabColumn}>
          <div>{COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB_DESCRIPTION}</div>
        </div>
        <div style={styles.tabColumn}>
          <div {...styles.searchBar} >
            <SearchBar
              placeholder={COPY.TRANSCRIPTION_FILE_DISPATCH_TYPE}
              size="big"
              id="transcription-table-search"
              isSearchAhead
              title={COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB_SEARCH}
            />
          </div>
        </div>
      </div>
      <div style={styles.tableWrapper}></div>
    </>
  }
];
