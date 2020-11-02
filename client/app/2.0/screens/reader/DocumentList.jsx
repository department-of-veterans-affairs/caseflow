// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

// Local Dependencies
import { fetchDocuments } from 'utils/reader/documents';
import { documentListScreen } from 'store/reader/selectors';
import { setSearch, clearSearch as clear, setViewingDocumentsOrComments } from 'store/reader/documentList';
import { recordSearch } from 'utils/reader';

import {
  QueueLink,
  ClaimsFolderDetails,
  DocumentListHeader,
  LastRetrievalAlert,
  LastRetrievalInfo
} from 'components/reader/DocumentList';
import DocumentsTable from 'app/reader/DocumentsTable';
import CommentsTable from 'app/reader/CommentsTable';

const DocumentList = (props) => {
  // Get the Document List state
  const state = useSelector(documentListScreen);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Load the Documents
  useEffect(fetchDocuments({ ...state, vacolsId: props.match.params.vacolsId }, dispatch), []);

  // Create the dispatchers
  const actions = {
    changeView: (val) => dispatch(setViewingDocumentsOrComments(val)),
    search: (val) => dispatch(setSearch(val, state.documentAnnotations, state.storeDocuments)),
    clearSearch: () => dispatch(clear(state.filterCriteria, state.documentAnnotations, state.storeDocuments)),
    recordSearch: (query) => recordSearch(props.match.params.vacolsId, query),
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
  loadedAppealId: PropTypes.string,
  documentAnnotations: PropTypes.array,

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  setCategoryFilter: PropTypes.func
};

export default DocumentList;
