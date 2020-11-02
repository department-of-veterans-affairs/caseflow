// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import Table from 'app/components/Table';
import {
  setDocListScrollPosition,
  changeSortState,
  clearTagFilters,
  clearCategoryFilters,
  setTagFilter,
  setCategoryFilter,
  toggleDropdownFilterVisibility
} from 'app/reader/DocumentList/DocumentListActions';
import { SortArrowUp, SortArrowDown } from 'app/components/RenderFunctions';
import { commentHeaders, documentHeaders } from 'components/reader/DocumentList/DocumentsTable/Columns';
import { documentRows, focusElement } from 'utils/reader';
import { selectCurrentPdfLocally, handleToggleCommentOpened } from 'app/reader/Documents/DocumentsActions';

/**
 * Documents Table Component
 * @param {Object} props -- Props contain documents and additional details from the redux store
 */
export const DocumentsTable = ({show, ...props}) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  // Setup the refs to control the scroll position
  const tbodyRef = React.createRef().current;
  const lastReadRef = React.createRef().current;
  const catFilterRef = React.createRef().current;
  const tagFilterRef = React.createRef().current;

  // Check the scroll position on mount
  useEffect(() => {
    // Only scroll if the scroll is set
    if (props.documentList.pdfList.scrollTop) {
      // Update the table body scroll position to the Last Read Row
      tbodyRef.scrollTop = focusElement(lastReadRef, tbodyRef);
    }

    // Reset the scroll position on Un-mount
    return () => dispatch(setDocListScrollPosition(tbodyRef?.scrollTop));
  }, []);

  // Create the Table Props to pass to the columns
  const tableProps = {
    ...props,
    tbodyRef,
    lastReadRef,
    catFilterRef,
    tagFilterRef,
    // Sort Functions
    changeSort: (val) => dispatch(changeSortState(val)),
    sortBy: props.filterCriteria.sort.sortBy,
    sortLabel: `Sorted ${props.filterCriteria.sort.sortAscending ? 'ascending' : 'descending'}`,
    sortIcon: props.filterCriteria.sort.sortAscending ? <SortArrowUp /> : <SortArrowDown />,
    // Filter Functions
    toggleFilter: (val) => dispatch(toggleDropdownFilterVisibility(val)),
    clearCategoryFilters: () => dispatch(clearCategoryFilters()),
    setCategoryFilter: (categoryName, checked) => dispatch(setCategoryFilter(categoryName, checked)),
    clearTagFilters: () => dispatch(clearTagFilters()),
    setTagFilter: (text, checked, tagId) => dispatch(setTagFilter(text, checked, tagId)),
    setPdf: (doc) => dispatch(selectCurrentPdfLocally(doc.id)),
    toggleComment: (docId, expanded) => dispatch(handleToggleCommentOpened(docId, expanded))
  };

  // Render The Table component
  return show && (
    <div>
      <Table
        columns={(row) => row?.isComment ? commentHeaders(tableProps) : documentHeaders(tableProps)}
        rowObjects={documentRows(props.documents, props.documentAnnotations)}
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
  show: PropTypes.bool,
  documents: PropTypes.object,
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
  setCategoryFilter: PropTypes.func,
  setTagFilter: PropTypes.func,
  setDocListScrollPosition: PropTypes.func,
  toggleDropdownFilterVisibility: PropTypes.func,
  tagOptions: PropTypes.arrayOf(PropTypes.object)
};
