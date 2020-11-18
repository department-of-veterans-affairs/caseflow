// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import classNames from 'classnames';

// Local Dependencies
import { pdfWrapper } from 'styles/reader/Document/Pdf';
import { fetchDocuments } from 'utils/reader/document';
import { documentScreen } from 'store/reader/selectors';
import { DocumentHeader } from 'components/reader/Document/Header';
import { DocumentSidebar } from 'components/reader/Document/Sidebar';
import { DocumentFooter } from 'components/reader/Document/Footer';
import { DocumentSearch } from 'app/2.0/components/reader/Document/Search';
import { Pdf } from 'app/2.0/components/reader/Document/PDF';

const Document = (props) => {
  // Get the Document List state
  const state = useSelector(documentScreen);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Attach the PDF Worker to the params to setup PDFJS
  const params = { ...props.match.params, worker: props.pdfWorker, currentDocument: state.currentDocument };

  // Load the Documents
  useEffect(fetchDocuments({ ...state, params }, dispatch), []);

  // Create the Grid Ref
  const gridRef = React.createRef().current;

  // Create the dispatchers
  const actions = {

  };

  return (
    <div className="cf-pdf-page-container">
      <div className={classNames('cf-pdf-container', { 'hidden-sidebar': state.hidePdfSidebar })} {...pdfWrapper}>
        <DocumentHeader
          {...state}
          documentPathBase={`/reader/appeal/${ state.appeal.id }/documents`}
          doc={state.currentDocument}
        />
        <DocumentSearch {...state} hidden={state.hideSearchBar} />
        <Pdf
          {...state}
          {...props}
          doc={state.currentDocument}
          gridRef={gridRef}
        />
        <DocumentFooter
          {...state}
          {...props}
          doc={state.currentDocument}
        />
      </div>
      <DocumentSidebar
        {...state}
        {...props}
        show={!state.hidePdfSidebar}
        comments={state.annotations}
        doc={state.currentDocument}
      />
    </div>
  );
};

Document.propTypes = {
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
  setCategoryFilter: PropTypes.func
};

export default Document;
