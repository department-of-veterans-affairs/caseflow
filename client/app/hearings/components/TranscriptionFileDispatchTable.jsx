import React, { useState } from 'react';
import PropTypes from 'prop-types';
import QueueTable from '../../queue/QueueTable';
import
{ selectColumn,
  docketNumberColumn,
  caseDetailsColumn,
  typesColumn,
  hearingDateColumn,
  hearingTypeColumn
} from './TranscriptionFileDispatchTableColumns';
import { css } from 'glamor';
import { encodeQueryParams } from '../../util/QueryParamsUtil';

const styles = css({
  '& div *': {
    outline: 'none'
  },
  '& .cf-form-textinput': {
    position: 'relative',
    top: '0.1em',
    marginLeft: '-0.01em',
    border: 'none',
    width: '44px',
  },
  '& thead > :first-child': {
    position: 'relative',
    top: '1em'
  },
  '& svg': {
    marginTop: '0.3em'
  },
  '& .cf-pagination-summary': {
    position: 'relative',
    top: '4em',
  },
  '& .cf-pagination:last-child .cf-pagination-summary': {
    top: '2em'
  },
  '& .cf-pagination-pages': {
    position: 'relative',
  },
  '& th:last-child .cf-dropdown-filter': {
    left: '-200px'
  }
});

export const TranscriptionFileDispatchTable = ({ columns, statusFilter }) => {
  const [transcriptionFiles] = useState([]);

  /**
   * Adds custom url params to the params used for pagenatation
   * @returns The url params needed to handle pagenation
   */
  const qs = encodeQueryParams({
    tab: statusFilter
  });

  /**
   * A map for the column to determine which function to use
   * @param {object} column - The current column
   * @returns The specific function used for the column
   */
  const createColumnObject = (column) => {
    const functionForColumn = {
      [columns.SELECT_ALL.name]: selectColumn(),
      [columns.DOCKET_NUMBER.name]: docketNumberColumn(),
      [columns.CASE_DETAILS.name]: caseDetailsColumn(),
      [columns.TYPES.name]: typesColumn(),
      [columns.HEARING_DATE.name]: hearingDateColumn(),
      [columns.HEARING_TYPE.name]: hearingTypeColumn()
    };

    return functionForColumn[column.name];
  };

  /**
   * Maps through a list of columns and find the function needed for each one
   * @param {object} cols - the columns json object which has every column an attribute
   * @returns The finished columns
   */
  const columnsFromConfig = (cols) => {
    return Object.values(cols).map((column) => createColumnObject(column));
  };

  /**
   * Restores any URL params as defaults in the QueryTable
   * @returns The restored params object
   */
  const getUrlParams = (query) =>
    Array.from(new URLSearchParams(query)).reduce((pValue, [kValue, vValue]) =>
      Object.assign({}, pValue, {
        [kValue]: pValue[kValue] ? (Array.isArray(pValue[kValue]) ?
          pValue[kValue] : [pValue[kValue]]).concat(vValue) : vValue
      }), {});

  return (
    <div {...styles} >
      <QueueTable
        columns={columnsFromConfig(columns)}
        rowObjects={transcriptionFiles}
        enablePagination
        casesPerPage={15}
        useTaskPagesApi
        taskPagesApiEndpoint={`/hearings/transcription_files/transcription_file_tasks${qs}`}
        anyFiltersAreSet
        tabPaginationOptions={getUrlParams(window.location.search)}
        getKeyForRow={(_, row) => row.id}
      />
    </div>
  );
};

TranscriptionFileDispatchTable.propTypes = {
  columns: PropTypes.objectOf(
    PropTypes.shape({
      name: PropTypes.string,
      filterable: PropTypes.bool || PropTypes.string
    })),
  statusFilter: PropTypes.arrayOf(PropTypes.string)
};
