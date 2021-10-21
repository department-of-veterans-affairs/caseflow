// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import Table from 'app/components/Table';
import { SortArrowUp, SortArrowDown } from 'app/components/RenderFunctions';
import { commentHeaders, documentHeaders } from 'components/reader/DocumentList/DocumentsTable/Columns';
import { documentRows } from 'utils/reader';
import { selectCurrentPdfLocally } from 'app/reader/Documents/DocumentsActions';

/**
 * Documents Table Component
 * @param {Object} props -- Props contain documents and additional details from the redux store
 */
export const DocumentsTable = ({ show, ...props }) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  // Setup the refs to control the scroll position
  const tbodyRef = React.createRef().current;
  const lastReadRef = React.createRef().current;
  const catFilterRef = React.createRef().current;
  const tagFilterRef = React.createRef().current;

  // Check the scroll position on mount
  useEffect(() => {
    // Get the last Read Indicator
    const lastRead = document.getElementById('read-indicator');

    // Focus the last read if present
    if (lastRead) {
      lastRead.scrollIntoView();
    }
  }, []);

  // Create the Table Props to pass to the columns
  const tableProps = {
    ...props,
    tbodyRef,
    lastReadRef,
    catFilterRef,
    tagFilterRef,
    // Sort Functions
    sortBy: props.filterCriteria.sort.sortBy,
    sortLabel: `Sorted ${props.filterCriteria.sort.sortAscending ? 'ascending' : 'descending'}`,
    sortIcon: props.filterCriteria.sort.sortAscending ? <SortArrowUp /> : <SortArrowDown />,
    // Filter Functions
    setPdf: (doc) => dispatch(selectCurrentPdfLocally(doc.id)),
  };

  // Render The Table component
  return show && (
    <div>
      <Table
        {...tableProps}
        columns={(row) => row?.isComment ? commentHeaders(tableProps) : documentHeaders(tableProps)}
        rowObjects={documentRows(props.filteredDocIds, props.documents, props.comments)}
        summary="Document list"
        className="documents-table"
        headerClassName="cf-document-list-header-row"
        bodyClassName="cf-document-list-body"
        rowsPerRowObject={2}
        tbodyId="documents-table-body"
        tbodyRef={tbodyRef}
        getKeyForRow={(_, { isComment, id }) => isComment ? `${id}-comment` : id}
      />
    </div>
  );
};

DocumentsTable.propTypes = {
  filteredDocIds: PropTypes.array,
  show: PropTypes.bool,
  documents: PropTypes.object,
  comments: PropTypes.array,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  documentList: PropTypes.shape({
    pdfList: PropTypes.object
  }),
  changeSortState: PropTypes.func,
  clearCategoryFilters: PropTypes.func,
  clearTagFilters: PropTypes.func,
  documentPathBase: PropTypes.string,
  annotationsPerDocument: PropTypes.object,
  filterCriteria: PropTypes.object,
  setTagFilter: PropTypes.func,
  setDocListScrollPosition: PropTypes.func,
  tagOptions: PropTypes.array
};
