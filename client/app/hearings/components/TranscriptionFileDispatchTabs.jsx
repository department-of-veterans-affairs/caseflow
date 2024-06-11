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

const searchBarStyles = css({
  '& input': {
    width: '100% !important'
  }
});

const styles = {
  rowstyles: {
    display: 'flex',
    justifyContent: 'space-between',
    marginBottom: '2em',
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
  tableStyles: {
    marginTop: '5em'
  },
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
 * A mini template component used on most of the tabs
 * @param {string} text - The descriptive text
 * @param {string} searchPrompt - The label text for the search bar prompt
 * @returns
 */
const Description = ({ text, searchPrompt }) => {
  return (
    <>
      <div className="tab-description" style={styles.rowstyles} >
        {text}
        <div style={styles.rowstyles} className="cf-search-ahead-parent">
          <div {...searchBarStyles}>
            <SearchBar
              placeholder="Type to search..."
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
export const tabConfig = [
  {
    label: COPY.CASE_LIST_TABLE_UNASSIGNED_LABEL,
    page: () => {
      return (
        <>
          <div className="tab-description" style={{ ...styles.rowstyles, marginTop: '-0.1em' }} >
          Transcription owned by the Transcription Team are unassigned to a contractor:
            <Link>
              <span style={styles.linkStyles}>
                Transcription settings
                <ExternalLinkIcon style={styles.linkIconStyles} color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
              </span>
            </Link>
          </div>
          <div style={{ ...styles.rowstyles, marginTop: '3em' }} className="cf-search-ahead-parent">
            Please select the files you would like to dispatch for transcription:
            <div {...searchBarStyles} >
              <SearchBar
                placeholder="Type to search..."
                size="big"
                id="transcription-table-search"
                isSearchAhead
                title="Search by Docket Number, Claimant Name, File Number, or SSN"
              />
            </div>
          </div>
          <div className="file-select" style={{ marginTop: '-2em' }}>
            <h2>0 files selected</h2>
            <div className="button-row" style={styles.buttonStyles} >
              <Button disabled>Package files</Button>
              <Button linkStyling>Cancel</Button>
            </div>
          </div>
          <div style={styles.tableStyles}>
            <TranscriptionFileDispatchTable
              columns={unassignedColumns(TRANSCRIPTION_FILE_DISPATCH_CONFIG.COLUMNS)}
              statusFilter={['Unassigned']}
            />
          </div>

        </>
      );
    }
  },
  {
    label: COPY.TRANSCRIPTION_DISPATCH_ASSIGNED_TAB,
    page: () => {
      return (
        <>
          <Description
            text="Transcription owned by the Transcription Team are returned from contractor:"
            searchPrompt="Search by work Order, Claimant Name, Docket Number, File Number or SSN"
          />
        </>
      );
    }
  },
  {
    label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
    page: () => {
      return (
        <>
          <Description
            text="Transcription owned by the Transcription Team are returned from contractor:"
            searchPrompt="Search by work Order, or Docket Number"
          />
        </>
      );
    }
  },
  {
    label: COPY.TRANSCRIPTION_FILE_DISPATCH_ALL_TAB,
    page: () => {
      return (
        <>
          <Description
            text="All transcription owned by the Transcription team:"
            searchPrompt="Search by work Order, or Docket Number"
          />
        </>
      );
    }
  }
];

Description.propTypes = {
  text: PropTypes.string,
  searchPrompt: PropTypes.string
};
