// External Dependencies
import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import { useDispatch, useSelector } from 'react-redux';
import { isEmpty } from 'lodash';

// Component Dependencies
import { DeleteComment } from 'components/reader/DocumentViewer/modals/Delete';
import { KeyboardInfo } from 'components/reader/DocumentViewer/modals/KeyboardInfo';
import { ShareComment } from 'components/reader/DocumentViewer/modals/Share';
import { File } from 'components/reader/DocumentViewer/PDF/File';
import { DocumentSearch } from 'components/reader/DocumentViewer/Search';
import { DocumentFooter } from 'components/reader/DocumentViewer/Footer';
import { DocumentHeader } from 'components/reader/DocumentViewer/Header';
import { DocumentSidebar } from 'components/reader/DocumentViewer/Sidebar';
import { LOGO_COLORS } from 'app/constants/AppConstants';
import { DEFAULT_VIEWPORT } from 'app/2.0/store/constants/reader';

// Functional Dependencies
import { documentScreen } from 'store/reader/selectors';
import { markDocAsRead } from 'store/reader/documentList';
import { pdfWrapper } from 'styles/reader/Document/PDF';
import { documentViewerActions } from 'utils/reader/actions';
import { fetchDocuments } from 'utils/reader/document';
import { loadContent } from 'utils/reader/pdf';
import ProgressBar from 'components/shared/ProgressBar';

const getPdf = (list, id, cachedPdf) => {
  if (!id) {
    return;
  }

  return isEmpty(list) ? cachedPdf : list[Number(id)];
};

let handle = 0;

const updateBoundaries = (setRendering) => () => {
  clearTimeout(handle); // ***
  handle = setTimeout(() => {
    setRendering(false);
    document.getElementsByClassName('cf-pdf-scroll-view')[0].style.marginTop = 0;
  }, 250);
};

/**
 * Document Viewer Screen Component
 * @param {Object} props -- Contains the route props
 */
const DocumentViewer = (props) => {
  const [cache, updateCache] = useState({});
  const [pdf, setPdf] = useState({});
  const [loadError, setLoadError] = useState(false);
  const [rotation, setRotation] = useState(0);
  const [scale, setScale] = useState(1);
  const [rendering, setRendering] = useState(true);

  // Get the PDF ID
  const pdfId = Number(props.match.params.docId);

  // Get the Document List state
  const state = useSelector(documentScreen(pdfId));
  const pdfMeta = getPdf(state.documents, pdfId, props.current_document);

  // Create the Dispatcher
  const dispatch = useDispatch();

  // Create the Grid Ref
  const gridRef = React.createRef();

  // Create the dispatchers
  const actions = documentViewerActions({
    ...props.match.params,
    setRendering,
    rotation,
    setRotation,
    scale,
    setScale,
    pdf,
    pdfId,
    state,
    dispatch,
    gridRef,
    history: props.history,
  });

  // Load the Documents
  useEffect(() => {
    document.addEventListener('rendering', () => {
      document.getElementsByClassName('cf-pdf-scroll-view')[0].style.marginTop = '10px';
      setRendering(true);
    });
    document.addEventListener('renderComplete', updateBoundaries(setRendering));

    loadContent({ cache, updateCache, setPdf, setLoadError, pdfMeta });
    // // Update the Document as read if not already
    // if (doc && !doc?.opened_by_current_user) {
    //   dispatch(markDocAsRead({ docId: doc.id }));
    // }

    if (isEmpty(state.documents)) {
      // Load the Documents
      fetchDocuments({ ...state, ...props.match }, dispatch)();
    }
  }, [pdfId]);

  return (
    <div id="document-viewer" className="cf-pdf-page-container" onClick={actions.deselectComment} >
      <div className={classNames('cf-pdf-container', { 'hidden-sidebar': state.hidePdfSidebar })} {...pdfWrapper}>
        <DocumentHeader {...props} {...state} {...actions} doc={pdf} />
        <DocumentSearch {...actions} {...state.search} doc={pdf} hidden={state.hideSearchBar} />
        <ProgressBar bgColor={LOGO_COLORS.QUEUE.ACCENT} initial={1} />
        <File
          {...props}
          {...state}
          {...actions}
          setRendering={setRendering}
          rendering={rendering}
          scale={scale}
          rotation={rotation}
          loadError={loadError}
          docId={pdfId}
          cache={cache}
          updateCache={updateCache}
          setPdf={setPdf}
          pdf={cache[pdfId]}
          gridRef={gridRef}
        />
        <DocumentFooter
          {...props}
          {...state}
          {...actions}
          nextDocId={state.filteredDocIds[state.filteredDocIds.indexOf(pdfId) + 1]}
          prevDocId={state.filteredDocIds[state.filteredDocIds.indexOf(pdfId) - 1]}
          currentIndex={state.filteredDocIds.indexOf(pdfId)}
          pdf={pdf}
        />
      </div>
      <DocumentSidebar {...props} {...state} {...actions} show={!state.hidePdfSidebar} pdf={pdf} />
      <ShareComment {...state} {...actions} show={state.shareCommentId !== null} commentId={state.shareCommentId} />
      <DeleteComment {...state} {...actions} show={state.deleteCommentId !== null} />
      <KeyboardInfo {...state} {...actions} show={state.keyboardInfoOpen} />
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
};

export default DocumentViewer;
