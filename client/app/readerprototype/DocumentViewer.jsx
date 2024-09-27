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
import { getRotationDeg } from './util/documentUtil';
import { ROTATION_DEGREES, ZOOM_INCREMENT, ZOOM_LEVEL_MAX, ZOOM_LEVEL_MIN } from './util/readerConstants';

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [numPages, setNumPages] = useState(null);
  const [rotateDeg, setRotateDeg] = useState('0deg');
  const [showSearchBar, setShowSearchBar] = useState(false);
  const [showSideBar, setShowSideBar] = useState(true);
  const dispatch = useDispatch();

  const currentDocumentId = Number(props.match.params.docId);
  const doc = props.allDocuments.find((x) => x.id === currentDocumentId);

  document.title = `${(doc && doc.type) || ''} | Document Viewer | Caseflow Reader`;

  useEffect(() => {
    setShowSearchBar(false);
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

  useEffect(() => {
    const keyHandler = (event) => {
      if (event.altKey && event.code === 'KeyM' && !event.shiftKey) {
        setShowSideBar(!showSideBar);
      }
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, [showSideBar]);

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

  const handleZoomIn = () => {
    const newZoomLevel = props.zoomLevel + ZOOM_INCREMENT;

    props.onZoomChange(newZoomLevel);
  };

  const handleZoomOut = () => {
    const newZoomLevel = props.zoomLevel - ZOOM_INCREMENT;

    props.onZoomChange(newZoomLevel);
  };

  useEffect(() => {
    document.body.style.overflow = 'hidden';

    return () => document.body.style.overflow = 'auto';
  }, [window.location.pathname]);

  return (
    <div id="prototype-reader" className="cf-pdf-page-container">
      <div id="prototype-reader-main">
        <ReaderToolbar
          disableZoomIn={props.zoomLevel === ZOOM_LEVEL_MAX}
          disableZoomOut={props.zoomLevel === ZOOM_LEVEL_MIN}
          doc={doc}
          documentPathBase={props.documentPathBase}
          resetZoomLevel={() => props.onZoomChange(100)}
          rotateDocument={() => setRotateDeg(getRotationDeg(rotateDeg))}
          setZoomInLevel={handleZoomIn}
          setZoomOutLevel={handleZoomOut}
          showClaimsFolderNavigation={props.allDocuments.length > 1}
          showSearchBar={showSearchBar}
          toggleSearchBar={setShowSearchBar}
          showSideBar={showSideBar}
          toggleSideBar={() => setShowSideBar(true)}
          zoomLevel={props.zoomLevel}
        />
        {showSearchBar && <ReaderSearchBar />}
        <div className="cf-pdf-scroll-view" onScroll={getPageNumFromScrollTop}>
          <PdfDocument
            doc={doc}
            rotateDeg={rotateDeg}
            setNumPages={setNumPages}
            zoomLevel={props.zoomLevel}
            currentPage={currentPage}
          />
        </div>
        <ReaderFooter
          currentPage={currentPage}
          docId={doc.id}
          numPages={numPages}
          setCurrentPage={() => setCurrentPage()}
          showPdf={props.showPdf}
        />
      </div>
      {showSideBar && (
        <ReaderSidebar
          doc={doc}
          showSideBar={showSideBar}
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
  match: PropTypes.object,
  zoomLevel: PropTypes.number,
  onZoomChange: PropTypes.func
};

export default DocumentViewer;
