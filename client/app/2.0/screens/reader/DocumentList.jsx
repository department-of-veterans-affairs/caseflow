// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

// Local Dependencies
import { fetchDocuments } from 'utils/reader/documents';
import { documentListScreen } from 'store/reader/selectors';

import { QueueLink, ClaimsFolderDetails, DocumentListHeader } from 'components/reader/DocumentList';
import LastRetrievalAlert from 'app/reader/LastRetrievalAlert';
import LastRetrievalInfo from 'app/reader/LastRetrievalInfo';
import DocumentsTable from 'app/reader/DocumentsTable';
import CommentsTable from 'app/reader/CommentsTable';

const DocumentList = ({ match }) => {
  // Get the Document List state
  const state = useSelector(documentListScreen);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Load the Documents
  useEffect(fetchDocuments({ ...state, vacolsId: match.params.vacolsId }, dispatch), []);

  return (
    <React.Fragment>
      {state.queueRedirectUrl && (
        <QueueLink {...state} veteranFullName={state.appeal.veteran_full_name} vbmsId={state.appeal.vbms_id} />
      )}
      <AppSegment filledBackground>
        <div className="section--document-list">
          <ClaimsFolderDetails {...state} />
          <LastRetrievalAlert {...state} />
          <DocumentListHeader {...state} noDocuments={state.documentsView === 'none'} />
        </div>
      </AppSegment>
      <LastRetrievalInfo />
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

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  setCategoryFilter: PropTypes.func
};

export default DocumentList;
