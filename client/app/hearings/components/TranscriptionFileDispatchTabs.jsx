import React from 'react';
import COPY from '../../../COPY';
import Link from '../../components/Link';
import { ExternalLinkIcon } from '../../components/icons/ExternalLinkIcon';
import { COLORS, ICON_SIZES } from '../../constants/AppConstants';
import SearchBar from '../../components/SearchBar';
import Button from '../../components/Button';
import PropTypes from 'prop-types';
import { TranscriptionFileDispatchTable } from './TranscriptionFileDispatchTable';
import { css } from 'glamor';
import TRANSCRIPTION_FILE_DISPATCH_CONFIG from '../../../constants/TRANSCRIPTION_FILE_DISPATCH_CONFIG';
import { sprintf } from 'sprintf-js';

const styles = {
  descriptionStyles: {
    display: 'flex',
    justifyContent: 'space-between',
    marginBottom: '4em',
  },
  linkStyles: {
    display: 'inline-flex',
    fontSize: 'small',
    cursor: 'pointer',
  },
  linkIconStyles: {
    marginLeft: '0.2em'
  },
  buttonStyles: {
    display: 'inline-block'
  },
  fileSelect: {
    margin: '-4.5em 0 2em 0'
  },
  searchBar: css({
    '& input': {
      width: '100% !important',
      maxWidth: '100%',
      marginTop: '0.5em'
    },
    '& .usa-search-big': {
      maxWidth: '100%',
      width: '550px'
    }
  })
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
 * A mini template component used on most of the tabs
 * @param {string} text - The descriptive text
 * @param {string} searchPrompt - The label text for the search bar prompt
 * @returns
 */
const Description = ({ text, searchPrompt }) => {
  return (
    <>
      <div className="tab-description" style={styles.descriptionStyles}>
        {text}
        <div className="cf-search-ahead-parent">
          <div {...styles.searchBar}>
            <SearchBar
              placeholder={COPY.TRANSCRIPTION_FILE_DISPATCH_TYPE}
              size="big"
              isSearchAhead
              title={searchPrompt}
            />
          </div>
        </div>
      </div>
    </>
  );
};

// This maps the component to render for each tab
export const tabConfig = (openPackageModal, selectFilesForPackage, files) => [
  {
    label: COPY.CASE_LIST_TABLE_UNASSIGNED_LABEL,
    page: <>
      <div className="tab-description" style={{ ...styles.descriptionStyles }} >
        {COPY.TRANSCRIPTION_FILE_DISPATCH_UNASSIGNED_TAB_DESCRIPTION}
        <Link linkStyling to="/find_by_contractor">
          <span style={styles.linkStyles}>
            {COPY.TRANSCRIPTION_FILE_DISPATCH_LINK}
            <span style={styles.linkIconStyles}>
              <ExternalLinkIcon style={styles.linkIconStyles} color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
            </span>
          </span>
        </Link>
      </div>
      <div style={{ ...styles.descriptionStyles }} className="cf-search-ahead-parent">
        {COPY.TRANSCRIPTION_FILE_DISPATCH_UNASSIGNED_TAB_PROMPT}
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
      <div className="file-select" style={styles.fileSelect}>
        <h2>{sprintf(COPY.TRANSCRIPTION_FILE_DISPATCH_FILE_SELECTED, files, files === 1 ? '' : 's')}</h2>
        <div className="button-row" style={styles.buttonStyles}>
          <Button disabled={files === 0} onClick={() => openPackageModal()}>Package files</Button>
          <Button linkStyling>Cancel</Button>
        </div>
      </div>
      <TranscriptionFileDispatchTable
        columns={unassignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
        statusFilter={['Unassigned']}
        selectFilesForPackage={selectFilesForPackage}
      />
    </>
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_ASSIGNED_TAB,
    page: <>
      <Description
        text={COPY.TRANSCRIPTION_FILE_DISPATCH_ASSIGNED_TAB_DESCRIPTION}
        searchPrompt={COPY.TRANSCRIPTION_FILE_DISPATCH_ASSIGNED_TAB_SEARCH}
      />
      <TranscriptionFileDispatchTable
        columns={assignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
        statusFilter={['Assigned']}
        selectFilesForPackage={selectFilesForPackage}
      />
    </>
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_COMPLETED_TAB,
    page: <>
      <Description
        text={COPY.TRANSCRIPTION_FILE_DISPATCH_COMPLETED_TAB_DESCRIPTION}
        searchPrompt={COPY.TRANSCRIPTION_FILE_DISPATCH_COMPLETED_TAB_SEARCH}
      />
    </>
  },
  {
    label: COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB,
    page: <>
      <Description
        text={COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB_DESCRIPTION}
        searchPrompt={COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB_SEARCH}
      />
    </>
  }
];

Description.propTypes = {
  text: PropTypes.string,
  searchPrompt: PropTypes.string
};
