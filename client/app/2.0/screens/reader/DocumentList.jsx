// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

// Local Dependencies
import { fetchDocuments } from 'utils/reader/document';
import { documentListScreen } from 'store/reader/selectors';
import {
  setSearch,
  clearSearch as clear,
  changeView,
  changeSortState,
  setCategoryFilter,
  toggleDropdownFilterVisibility,
  clearCategoryFilters,
  clearAllFilters,
  clearTagFilters,
  setTagFilter,
  toggleComment,
  markDocAsRead,
} from 'store/reader/documentList';
import { recordSearch } from 'utils/reader';

import {
  QueueLink,
  ClaimsFolderDetails,
  DocumentListHeader,
  LastRetrievalAlert,
  LastRetrievalInfo,
  NoSearchResults,
  DocumentsTable,
  CommentsTable,
} from 'components/reader/DocumentList';

const DocumentList = (props) => {
  // Get the Document List state
  const state = useSelector(documentListScreen);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Load the Documents
  useEffect(fetchDocuments({ ...state, params: props.match.params }, dispatch), []);

  // Create the dispatchers
  const actions = {
    toggleComment: (docId, expanded) => dispatch(toggleComment({ docId, expanded })),
    clearTagFilters: () => dispatch(clearTagFilters(state)),
    setTagFilter: (text, checked, tagId) => dispatch(setTagFilter(text, checked, tagId, state)),
    clearAllFilters: () => dispatch(clearAllFilters(state)),
    clearCategoryFilters: () => dispatch(clearCategoryFilters(state)),
    toggleFilter: (val) => dispatch(toggleDropdownFilterVisibility(val)),
    setCategoryFilter: (categoryName, checked) => dispatch(setCategoryFilter(categoryName, checked, state)),
    changeView: (val) => dispatch(changeView(val)),
    search: (val) => dispatch(setSearch(val, state.comments, state.storeDocuments)),
    clearSearch: () => dispatch(clear(state.filterCriteria, state.comments, state.storeDocuments)),
    recordSearch: (query) => recordSearch(props.match.params.vacolsId, query),
    changeSort: (val) => dispatch(changeSortState(val, state)),
    showPdf: (docId) => {
      // const currentDocument = state.documents[docId];

      // // Update the Document as read if not already
      // if (!currentDocument.opened_by_current_user) {
      //   dispatch(markDocAsRead({ docId }));
      // }
    }
  };

  return (
    <React.Fragment>
      {state.queueRedirectUrl && (
        <QueueLink {...state} veteranFullName={state.appeal.veteran_full_name} vbmsId={state.appeal.vbms_id} />
      )}
      <AppSegment filledBackground>
        <div className="section--document-list">
          <ClaimsFolderDetails {...state} />
          <LastRetrievalAlert {...state.documentList} appeal={state.appeal} />
          <DocumentListHeader {...state} {...actions} />
          <NoSearchResults {...state} {...actions} show={state.documentsView === 'none'} />
          <DocumentsTable
            {...state}
            {...actions}
            documentPathBase={`/reader/appeal/${ state.appeal.id }/documents`}
            show={state.documentsView === 'documents'}
          />
          <CommentsTable
            {...state}
            {...actions}
            documentPathBase={`/reader/appeal/${ state.appeal.id }/documents`}
            show={state.documentsView === 'comments'}
          />
        </div>
      </AppSegment>
      <LastRetrievalInfo {...state.documentList} />
    </React.Fragment>
  );
};

DocumentList.propTypes = {
  appeal: PropTypes.object,
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  singleDocumentMode: PropTypes.bool,
  match: PropTypes.object,
  annotations: PropTypes.array,

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  setCategoryFilter: PropTypes.func,
};

export default DocumentList;
