import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';

import PdfDocument from './components/PdfDocument';
import ReaderFooter from './components/ReaderFooter';
import ReaderSearchBar from './components/ReaderSearchBar';
import ReaderSidebar from './components/ReaderSidebar';
import ReaderToolbar from './components/ReaderToolbar';

import { useDispatch } from 'react-redux';
import { CATEGORIES } from '../reader/analytics';
import { stopPlacingAnnotation } from '../reader/AnnotationLayer/AnnotationActions';
import DeleteModal from './components/Comments/DeleteModal';
import ShareModal from './components/Comments/ShareModal';
import { getRotationDeg, selectedDoc } from './utils/utils';
import { ROTATION_DEGREES, ZOOM_LEVEL_MIN, ZOOM_LEVEL_MAX, ZOOM_INCREMENT } from './utils/constants';
import { documentStyles } from './utils/styles';

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [numPages, setNumPages] = useState(null);
  const [rotateDeg, setRotateDeg] = useState('0deg');
  const [showSearchBar, setShowSearchBar] = useState(false);
  const [showSideBar, setShowSideBar] = useState(true);
  const [zoomLevel, setZoomLevel] = useState(100);
  const [disabled, setDisabled] = useState(true);
  const dispatch = useDispatch();

  const currentDocumentId = Number(props.match.params.docId);

  const doc = selectedDoc(props);

  useEffect(() => {
    setShowSearchBar(false);
    document.title = `${(doc && doc.type) || ''} | Document Viewer | Caseflow Reader`;
  }, [currentDocumentId]);

  useEffect(() => {
    const keyHandler = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setShowSearchBar(false);
      }

      if (event.metaKey && event.code === 'KeyF') {
        event.preventDefault();
        setShowSearchBar(true);
      }

      if (event.altKey && event.code === 'Backspace') {
        window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
        dispatch(stopPlacingAnnotation('from-back-to-documents'));
        props.history.push(props.documentPathBase);
      }
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, []);

  const getPageNumFromScrollTop = (event) => {
    const { clientHeight, scrollTop, scrollHeight } = event.target;
    const pageHeightEstimate =
      rotateDeg === ROTATION_DEGREES.NINETY || rotateDeg === ROTATION_DEGREES.TWO_SEVENTY ?
        clientHeight :
        scrollHeight / numPages;
    const pageNumber = Math.ceil((pageHeightEstimate + scrollTop) / pageHeightEstimate);

    if (pageNumber > numPages) {
      setCurrentPage(numPages);
    } else {
      setCurrentPage(pageNumber);
    }
  };

  useEffect(() => {
    if (window.location.pathname.includes('/documents/')) {
      document.body.style.overflow = 'hidden';
    }

    return () => document.body.style.overflow = 'auto';
  }, [window.location.pathname]);

  return (
    <div className="cf-pdf-page-container" style={documentStyles.container}>
      <div style={documentStyles.main}>
        <ReaderToolbar
          disableZoomIn={zoomLevel === ZOOM_LEVEL_MAX}
          disableZoomOut={zoomLevel === ZOOM_LEVEL_MIN}
          doc={doc}
          documentPathBase={props.documentPathBase}
          resetZoomLevel={() => setZoomLevel(100)}
          rotateDocument={() => setRotateDeg(getRotationDeg(rotateDeg))}
          setZoomInLevel={() => setZoomLevel(zoomLevel + ZOOM_INCREMENT)}
          setZoomOutLevel={() => setZoomLevel(zoomLevel - ZOOM_INCREMENT)}
          showClaimsFolderNavigation={props.allDocuments.length > 1}
          showSearchBar={showSearchBar}
          toggleSearchBar={setShowSearchBar}
          showSideBar={showSideBar}
          toggleSideBar={() => setShowSideBar(true)}
          zoomLevel={zoomLevel}
        />
        {showSearchBar && <ReaderSearchBar />}
        <div className="cf-pdf-scroll-view" onScroll={getPageNumFromScrollTop}>
          <PdfDocument
            doc={doc}
            rotateDeg={rotateDeg}
            setNumPages={setNumPages}
            zoomLevel={zoomLevel}
            onLoad={setDisabled}
          />
        </div>
        <ReaderFooter
          currentPage={currentPage}
          docId={doc.id}
          match={props.match}
          numPages={numPages}
          setCurrentPage={() => setCurrentPage()}
          showPdf={props.showPdf}
        />
      </div>
      {showSideBar && (
        <ReaderSidebar
          doc={doc}
          toggleSideBar={() => setShowSideBar(false)}
          vacolsId={props.match.params.vacolsId}
        />
      )}
      <DeleteModal documentId={currentDocumentId} />
      <ShareModal />
    </div>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.array,
  documentPathBase: PropTypes.string,
  featureToggles: PropTypes.object,
  fetchAppealDetails: PropTypes.func,
  history: PropTypes.any,
  showPdf: PropTypes.func,
  match: PropTypes.object
};

export default DocumentViewer;
