import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import QueueTable from '../../queue/QueueTable';
import {
  selectColumn,
  docketNumberColumn,
  caseDetailsColumn,
  typesColumn,
  hearingDateColumn,
  hearingTypeColumn,
  workOrderColumn,
  itemsColumn,
  dateSentColumn,
  expectedReturnDateColumn,
  contractorColumn,
  statusColumn,
  unassignColumn,
  returnDateColumn,
  uploadDateColumn
} from './TranscriptionFileDispatchTableColumns';
import { css } from 'glamor';
import { encodeQueryParams } from '../../util/QueryParamsUtil';
import ApiUtil from '../../util/ApiUtil';
import WorkOrderUnassignModal from './transcriptionProcessing/WorkOrderUnassignModal';

const styles = css({
  '& div *': {
    outline: 'none',
  },
  '& table': {
    marginTop: '0',
    position: 'relative',
    top: '-1em',
  },
  '& thead': {
    margin: '-2em 0 0 0',
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
    top: '1em',
  },
  '& svg': {
    marginTop: '0.3em',
  },
  '& .cf-pagination-summary': {
    position: 'relative',
    top: '0.4em',
    margin: '0',
  },
  '& .cf-pagination-pages': {
    margin: '0',
  },
  '& th:last-child .cf-dropdown-filter': {
    left: '-231px',
  },
  '& .cf-table-wrapper': {
    minHeight: '620px',
    overflow: 'unset',
  },
});

export const TranscriptionFileDispatchTable = ({
  columns,
  statusFilter,
  selectFilesForPackage,
  openModal,
}) => {
  const [tableData, setTableData] = useState([]);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [selectingFile, setSelectingFile] = useState(false);
  const [contractors, setContractors] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalData, setModalData] = useState({ workOrderNumber: null });

  /**
   * Callback passed into the Queue Table triggered when the unassign link is clicked
   * @param {object} workOrderNumber - work order number of package
   */
  const unassignPackage = (workOrderNumber) => {
    setModalData({ workOrderNumber });
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setModalData({ workOrderNumber: null });
  };

  /**
   * Callback passed into the Queue Table triggered when the work order is clicked
   * @param {number} id - id of package
   */
  const downloadFile = () => {
    // do something
  };

  /**
   * Callback passed into the Queue Table triggered when table is updated from the API
   */
  const tableDataUpdated = (rows) => {
    setTableData(rows);
  };

  /**
   * Get the most recent locked status of files from the backend
   * including files locked by other users
   */
  const getFileStatuses = () => {
    ApiUtil.get('/hearings/transcription_files/locked').then((response) => {
      if (!selectingFile) {
        setSelectedFiles(response.body);
        selectFilesForPackage(response.body);
      }
    });
  };

  /**
   * Get the list of transcription contractors for use in the filter
   */
  const getContractors = () => {
    ApiUtil.get('/hearings/find_by_contractor/filterable_contractors').then(
      (response) =>
        // eslint-disable-next-line camelcase
        setContractors(response.body?.transcription_contractors)
    );
  };

  /**
   * Adds custom url params to the params used for pagination
   * @returns The url params needed to handle pagination
   */
  const qs = encodeQueryParams({
    tab: statusFilter[0]
  });

  /**
   * Sets the correct API endpoint based on the tab we're in
   * @returns The url string
   */
  const apiEndpoint = () => {
    if (!statusFilter || statusFilter[0] === 'Unassigned' || statusFilter[0] === 'Completed' || statusFilter[0] === 'All') {
      return `/hearings/transcription_files/transcription_file_tasks${qs}`;
    } else if (statusFilter[0] === 'Assigned') {
      return `/hearings/transcription_packages/transcription_package_tasks${qs}`;
    }
  };

  /**
   * Calls to the backend to select or unselect a set of file IDs
   * @param {array} ids - list of ids to update
   * @param {string} value - Selecting or unselecting
   */
  const selectFiles = (ids, value) => {
    setSelectingFile(true);
    let newlySelectedFiles;

    if (value) {
      newlySelectedFiles = selectedFiles.concat(
        ids.map((id) => ({ id, status: 'selected' }))
      );
    } else {
      newlySelectedFiles = selectedFiles.filter(
        (file) => !ids.includes(file.id)
      );
    }

    setSelectedFiles(newlySelectedFiles);
    selectFilesForPackage(newlySelectedFiles);

    const data = {
      file_ids: ids,
      status: value,
    };

    // send lock requests and return actual list of locks to refresh the view
    ApiUtil.post('/hearings/transcription_files/lock', { data }).then(
      (response) => {
        setSelectingFile(false);
        setSelectedFiles(response.body);
        selectFilesForPackage(response.body);
      }
    );
  };

  /**
   * Callback passed into tabs that will find the IDs of all files in the current table
   * page that need to be selected or unselected
   * @param {string} value - Selecting or unselecting
   */
  const selectAllFiles = (value) => {
    const lockedFileIds = selectedFiles.
      filter((file) => file.status === 'locked').
      map((file) => file.id);
    const ids = tableData.
      filter((file) => !lockedFileIds.includes(file.id)).
      map((file) => file.id);

    selectFiles(ids, value);
  };

  /**
   * A map for the column to determine which function to use
   * @param {object} column - The current column
   * @returns The specific function used for the column
   */
  const createColumnObject = (column) => {
    const functionForColumn = {
      selectColumn: selectColumn(
        selectFiles,
        selectAllFiles,
        selectedFiles,
        tableData
      ),
      docketNumberColumn: docketNumberColumn(),
      caseDetailsColumn: caseDetailsColumn(),
      typesColumn: typesColumn(),
      hearingDateColumn: hearingDateColumn(),
      hearingTypeColumn: hearingTypeColumn(),
      workOrderColumn: workOrderColumn(downloadFile),
      itemsColumn: itemsColumn(openModal),
      dateSentColumn: dateSentColumn(),
      returnDateColumn: returnDateColumn(),
      expectedReturnDateColumn: expectedReturnDateColumn(),
      contractorColumn: contractorColumn(contractors),
      statusColumn: statusColumn(statusFilter[0]),
      unassignColumn: unassignColumn(unassignPackage),
      uploadDateColumn: uploadDateColumn(),
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
    Array.from(new URLSearchParams(query)).reduce(
      (pValue, [kValue, vValue]) =>
        Object.assign({}, pValue, {
          [kValue]: pValue[kValue] ?
            (Array.isArray(pValue[kValue]) ?
              pValue[kValue] :
              [pValue[kValue]]).concat(vValue) : vValue,
        }),
      {}
    );

  /**
   * Call for initial selection statuses and set interval to keep refreshing them
   */
  useEffect(() => {
    if (statusFilter[0] === 'Unassigned') {
      getFileStatuses();
      const interval = setInterval(() => {
        getFileStatuses();
      }, 3000);

      return () => clearInterval(interval);
    } else if (statusFilter[0] === 'Assigned') {
      getContractors();
    }
  }, []);

  return (
    <div {...styles}>
      <QueueTable
        columns={columnsFromConfig(columns)}
        rowObjects={[]}
        enablePagination
        casesPerPage={15}
        useTaskPagesApi
        taskPagesApiEndpoint={apiEndpoint()}
        anyFiltersAreSet
        tabPaginationOptions={getUrlParams(window.location.search)}
        getKeyForRow={(_, row) => row.id}
        onTableDataUpdated={tableDataUpdated}
        skipCache
      />
      {isModalOpen && (
        <WorkOrderUnassignModal
          onClose={closeModal}
          workOrderNumber={modalData.workOrderNumber}
        />
      )}
    </div>
  );
};

TranscriptionFileDispatchTable.propTypes = {
  columns: PropTypes.objectOf(
    PropTypes.shape({
      name: PropTypes.string,
      filterable: PropTypes.bool || PropTypes.string,
    })
  ),
  statusFilter: PropTypes.arrayOf(PropTypes.string),
  selectAll: PropTypes.func,
  selectFilesForPackage: PropTypes.func,
  openModal: PropTypes.func,
};
