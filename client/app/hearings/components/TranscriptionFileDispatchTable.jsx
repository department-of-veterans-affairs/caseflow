import React, { useEffect, useState } from 'react';
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
import ApiUtil from '../../util/ApiUtil';
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
    top: '2em'
  },
  '& .cf-pagination-pages': {
    position: 'relative',
  }
});

export const TranscriptionFileDispatchTable = ({ columns, statusFilter }) => {
  const [transcriptionFiles, setTranscriptionFiles] = useState([]);

  const qs = encodeQueryParams({
    tab: statusFilter
  });

  const getTranscriptionFiles = () =>
    ApiUtil.get(`/hearings/transcription_files/unassigned${qs}`).then((response) => {
      setTranscriptionFiles(response.body.tasks.data);
    });

  useEffect(() => {
    getTranscriptionFiles();
  }, []);

  /**
   * A map for the column to determine which function to use
   * @param {object} column - The current column
   * @returns The specific function used for the column
   */
  const createColumnObject = (column) => {
    const functionForColumn = {
      [columns.SELECT_ALL.name]: selectColumn(transcriptionFiles),
      [columns.DOCKET_NUMBER.name]: docketNumberColumn(transcriptionFiles),
      [columns.CASE_DETAILS.name]: caseDetailsColumn(transcriptionFiles),
      [columns.TYPES.name]: typesColumn(transcriptionFiles),
      [columns.HEARING_DATE.name]: hearingDateColumn(transcriptionFiles),
      [columns.HEARING_TYPE.name]: hearingTypeColumn(transcriptionFiles)
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

  /*
  const pageLoaded = (response, currentPage) => {
    console.log('onPageLoaded');
    console.log(response);
    console.log(currentPage);
    if (!response) {
      return;
    }
  };

  const tabPaginationOptions = {
    onPageLoaded: pageLoaded
  };
  */

  return (
    <div {...styles} >
      <QueueTable
        columns={columnsFromConfig(columns)}
        rowObjects={transcriptionFiles}
        enablePagination
        // tabPaginationOptions={tabPaginationOptions}
        casesPerPage={15}
        useTaskPagesApi
        taskPagesApiEndpoint={`/hearings/transcription_files/transcription_file_tasks${qs}`}
        defaultSort={{
          sortColName: 'hearingDateColumn',
          sortAscending: true
        }}
        anyFiltersAreSet
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
