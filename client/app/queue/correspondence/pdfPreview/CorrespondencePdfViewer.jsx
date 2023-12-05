import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';

// Reader & Component Imports
import PdfUI from '../../../reader/PdfUI';

// Reader Actions & Redux Imports
import { fetchAppealDetails, showSearchBar } from '../../../reader/PdfViewer/PdfViewerActions';
import { selectCurrentPdf } from '../../../reader/Documents/DocumentsActions';
import { shouldFetchAppeal } from '../../../reader/utils';
import { bindActionCreators } from 'redux';
import { getFilteredDocuments } from '../../../reader/selectors';
import Pdf from '../../../reader/Pdf';

export const CorrespondencePdfViewer = ({
  handleSelectCurrentPdf,
  match,
  appeal,
  documents,
  allDocuments,
  documentPathBase,
  featureToggles,
  ...props
}) => {

  const selectedDocId = () => Number(match.params.docId);
  const selectedDocIndex = () => _.findIndex(documents, { id: selectedDocId() });
  const selectedDoc = () => documents[selectedDocIndex()];

  const getPrevDoc = () => _.get(documents, [selectedDocIndex() - 1]);
  const getNextDoc = () => _.get(documents, [selectedDocIndex() + 1]);

  const getPrevDocId = () => _.get(getPrevDoc(), 'id');
  const getNextDocId = () => _.get(getNextDoc(), 'id');

  const getPrefetchFiles = () => _.compact(_.map([getPrevDoc(), getNextDoc()], 'content_url'));

  const showClaimsFolderNavigation = () => allDocuments.length > 1;

  const doc = selectedDoc();
  // eslint-disable-next-line max-statements

  useEffect(() => {
    handleSelectCurrentPdf(selectedDocId());

    if (shouldFetchAppeal(appeal, match.params.vacolsId)) {
      fetchAppealDetails(match.params.vacolsId);
    }

  }, [appeal, match.params.vacolsId]);

  useEffect(() => {
    handleSelectCurrentPdf(Number(match.params.docId));
  }, [match.params.docId]);

  /* eslint-enable camelcase */

  // If we don't have a currently selected document, we
  // shouldn't render anything. On the next tick we dispatch
  // the action to redux that populates the documents and then we
  // render
  // TODO(jd): We should refactor and potentially create the store
  // with the documents already added
  if (!doc) {
    return null;
  }

  return (
    <div>
      <div className="cf-pdf-page-container">
        {/* <PdfUI
          doc={doc}
          prefetchFiles={getPrefetchFiles()}
          id="pdf"
          documentPathBase={documentPathBase}
          prevDocId={getPrevDocId()}
          nextDocId={getNextDocId()}
          history={props.history}
          showPdf={props.showPdf}
          showClaimsFolderNavigation={showClaimsFolderNavigation()}
          featureToggles={featureToggles}
        /> */}
      </div>
      {doc.wasUpdated}
    </div>
  );
};

const mapStateToProps = (state) => ({
  documents: getFilteredDocuments(state),
  appeal: state.pdfViewer.loadedAppeal,
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    fetchAppealDetails,
    showSearchBar,
  }, dispatch),

  handleSelectCurrentPdf: (docId) => dispatch(selectCurrentPdf(docId))
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(CorrespondencePdfViewer);

CorrespondencePdfViewer.propTypes = {
  appeal: PropTypes.object,
  closeDocumentUpdatedModal: PropTypes.func,
  doc: PropTypes.object,
  documentPathBase: PropTypes.string,
  featureToggles: PropTypes.object,
  fetchAppealDetails: PropTypes.func,
  handleSelectCurrentPdf: PropTypes.func,
  history: PropTypes.object,
  match: PropTypes.object,
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  showPdf: PropTypes.func
};
