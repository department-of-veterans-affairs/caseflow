// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useSelector, useDispatch } from 'react-redux';
import classNames from 'classnames';

// Local Dependencies
import { pdfWrapper } from 'styles/reader/Document/Pdf';
import { fetchDocuments, openDownloadLink } from 'utils/reader/document';
import { documentScreen } from 'store/reader/selectors';
import { DocumentHeader } from 'components/reader/DocumentViewer/Header';
import { DocumentSidebar } from 'components/reader/DocumentViewer/Sidebar';
import { DocumentFooter } from 'components/reader/DocumentViewer/Footer';
import { DocumentSearch } from 'app/2.0/components/reader/DocumentViewer/Search';
import { Pdf } from 'app/2.0/components/reader/DocumentViewer/PDF';
import { ZOOM_RATE, MINIMUM_ZOOM, CATEGORIES } from 'app/2.0/store/constants/reader';
import { ShareComment } from 'app/2.0/components/reader/DocumentViewer/modals/Share';
import { DeleteComment } from 'app/2.0/components/reader/DocumentViewer/modals/Delete';
import {
  showPdf,
  togglePdfSideBar,
  setOpenedAccordionSections,
  toggleShareModal,
  toggleDeleteModal,
  setOverscanValue,
  saveDescription,
  changeDescription,
  resetDescription,
  handleCategoryToggle
} from 'store/reader/documentViewer';

const DocumentViewer = (props) => {
  // Get the Document List state
  const state = useSelector(documentScreen);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Attach the PDF Worker to the params to setup PDFJS
  const params = {
    ...props.match.params,
    worker: props.pdfWorker,
    currentDocument: state.currentDocument,
    scale: state.scale
  };

  // Calculate the Next and Prev Docs
  const docs = {
    prev: state.filteredDocIds[state.filteredDocIds.indexOf(state.currentDocument.id) - 1],
    current: state.filteredDocIds.indexOf(state.currentDocument.id),
    next: state.filteredDocIds[state.filteredDocIds.indexOf(state.currentDocument.id) + 1],
  };

  // Load the Documents
  useEffect(fetchDocuments({ ...state, params }, dispatch), []);

  // Create the Grid Ref
  const gridRef = React.createRef();

  // Create the dispatchers
  const actions = {
    saveDescription: (description) => dispatch(saveDescription({ docId: state.currentDocument.id, description })),
    changeDescription: (description) => dispatch(changeDescription(description)),
    resetDescription: () => dispatch(resetDescription()),
    setOverscanValue: (val) => dispatch(setOverscanValue(val)),
    handleCategoryToggle: (categoryKey, toggleState) => dispatch(handleCategoryToggle({
      docId: state.currentDocument.id,
      categoryKey,
      toggleState
    })),
    closeShareModal: () => dispatch(toggleShareModal(null)),
    closeDeleteModal: () => dispatch(toggleDeleteModal(null)),
    shareComment: (id) => dispatch(toggleShareModal(id)),
    deleteComment: (id) => dispatch(toggleDeleteModal(id)),
    toggleAccordion: (sections) => dispatch(setOpenedAccordionSections(sections)),
    togglePdfSidebar: () => dispatch(togglePdfSideBar()),
    download: () => openDownloadLink(state.currentDocument.content_url, state.currentDocument.type),
    scrollPage: ({ scrollTop, scrollLeft }) => {
      gridRef.current?.scrollToPosition({ scrollLeft, scrollTop });
    },
    overscanIndices: ({ cellCount, overscanCellsCount, startIndex, stopIndex }) => ({
      overscanStartIndex: Math.max(0, startIndex - Math.ceil(overscanCellsCount / 2)),
      overscanStopIndex: Math.min(cellCount - 1, stopIndex + Math.ceil(overscanCellsCount / 2))
    }),
    fitToScreen: () => {
      window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'fit to screen');

      dispatch(showPdf({
        currentDocument: state.currentDocument,
        worker: props.pdfWorker,
        scale: 1
      }));
    },
    rotateDocument: () => {
      dispatch(showPdf({
        currentDocument: state.currentDocument,
        rotation: state.currentDocument.rotation,
        worker: props.pdfWorker,
        scale: state.scale
      }));
    },
    zoom: (direction) => {
      // Determine the Amount to zoom based on the direction
      const delta = direction === 'in' ? ZOOM_RATE : -ZOOM_RATE;

      // Calculate the new Scale to zoom the document
      const scale = Math.min(Math.max(MINIMUM_ZOOM, state.scale + delta), 2);

      window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `zoom ${direction}`, scale);

      dispatch(showPdf({ currentDocument: state.currentDocument, worker: props.pdfWorker, scale }));
    },
    setPageNumber: (pageNumber) => dispatch(showPdf({
      pageNumber,
      pageIndex: pageNumber - 1,
      currentDocument: state.currentDocument,
      worker: props.pdfWorker,
      scale: state.scale
    })),
    prevDoc: () => {
      const doc = state.documents[docs.prev];

      props.history.push(`/reader/appeal/${params.vacolsId}/documents/${doc.id}`);

      dispatch(showPdf({ currentDocument: doc, worker: props.pdfWorker, scale: state.scale }));
    },
    nextDoc: () => {
      const doc = state.documents[docs.next];

      props.history.push(`/reader/appeal/${params.vacolsId}/documents/${doc.id}`);

      dispatch(showPdf({ currentDocument: doc, worker: props.pdfWorker, scale: state.scale }));
    }
  };

  return (
    <div className="cf-pdf-page-container">
      <div className={classNames('cf-pdf-container', { 'hidden-sidebar': state.hidePdfSidebar })} {...pdfWrapper}>
        <DocumentHeader
          {...state}
          {...actions}
          documentPathBase={`/reader/appeal/${ state.appeal.id }/documents`}
          doc={state.currentDocument}
        />
        <DocumentSearch {...state} doc={state.currentDocument} hidden={state.hideSearchBar} />
        <Pdf
          {...state}
          {...props}
          {...actions}
          doc={state.currentDocument}
          gridRef={gridRef}
        />
        <DocumentFooter
          {...state}
          {...props}
          {...actions}
          nextDocId={docs.next > 0 ? docs.next : 0}
          prevDocId={docs.prev > 0 ? docs.prev : 0}
          currentIndex={docs.current}
          doc={state.currentDocument}
        />
      </div>
      <DocumentSidebar
        {...state}
        {...props}
        {...actions}
        show={!state.hidePdfSidebar}
        doc={state.currentDocument}
      />
      <ShareComment {...state} {...actions} show={state.shareCommentId !== null} commentId={state.shareCommentId} />
      <DeleteComment {...state} {...actions} show={state.deleteCommentId !== null} />
    </div>
  );
};

DocumentViewer.propTypes = {
  appeal: PropTypes.object,
  history: PropTypes.object,
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  singleDocumentMode: PropTypes.bool,
  match: PropTypes.object,
  annotations: PropTypes.array,

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
};

export default DocumentViewer;
