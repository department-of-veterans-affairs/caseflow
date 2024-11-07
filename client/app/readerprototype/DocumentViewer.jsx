import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import { Helmet } from 'react-helmet';
import PdfDocument from './components/PdfDocument';
import ReaderFooter from './components/ReaderFooter';
import ReaderSearchBar from './components/ReaderSearchBar';
import ReaderSidebar from './components/ReaderSidebar';
import ReaderToolbar from './components/ReaderToolbar';

import { useDispatch, useSelector } from 'react-redux';
import { CATEGORIES } from '../reader/analytics';
import { stopPlacingAnnotation } from '../reader/AnnotationLayer/AnnotationActions';
import DeleteModal from './components/Comments/DeleteModal';
import ShareModal from './components/Comments/ShareModal';
import { getRotationDeg } from './util/documentUtil';
import { ROTATION_DEGREES, ZOOM_INCREMENT, ZOOM_LEVEL_MAX, ZOOM_LEVEL_MIN } from './util/readerConstants';
import { showSideBarSelector } from './selectors';
import { togglePdfSidebar } from '../reader/PdfViewer/PdfViewerActions';

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [numPages, setNumPages] = useState(null);
  const [rotateDeg, setRotateDeg] = useState('0deg');
  const [showSearchBar, setShowSearchBar] = useState(false);
  const [isDocumentLoadError, setIsDocumentLoadError] = useState(false);
  const showSideBar = useSelector(showSideBarSelector);
  const dispatch = useDispatch();

  const currentDocumentId = Number(props.match.params.docId);
  const doc = props.allDocuments.find((x) => x.id === currentDocumentId);

  useEffect(() => {
    setShowSearchBar(false);
  }, [currentDocumentId]);

  useEffect(() => {
    const keyHandler = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setShowSearchBar(false);
      }
      const metaKey = navigator.appVersion.includes('Win') ? 'ctrlKey' : 'metaKey';

      if (event[metaKey] && event.code === 'KeyF') {
        event.preventDefault();
        setShowSearchBar(true);
      }

      if (event.altKey && event.code === 'Backspace') {
        window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
        props.history.push(props.documentPathBase);
      }

      if (event.altKey && event.code === 'KeyM' && !event.shiftKey) {
        dispatch(togglePdfSidebar());
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

  useEffect(() => {
    dispatch(stopPlacingAnnotation('navigation'));
  }, [doc.id, dispatch]);

  return (
    <>
      <Helmet key={doc?.id}>
        <title>{`${(doc?.type) || ''} | Document Viewer | Caseflow Reader`}</title>
      </Helmet>
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
            toggleSideBar={() => dispatch(togglePdfSidebar())}
            zoomLevel={props.zoomLevel}
          />
          {showSearchBar && <ReaderSearchBar />}
          <div className="cf-pdf-scroll-view" onScroll={getPageNumFromScrollTop}>
            <PdfDocument
              currentPage={currentPage}
              doc={doc}
              isDocumentLoadError={isDocumentLoadError}
              rotateDeg={rotateDeg}
              setIsDocumentLoadError={setIsDocumentLoadError}
              setNumPages={setNumPages}
              zoomLevel={props.zoomLevel}
              progressBarOptions={props.progressBarOptions}
              onrequestCancel={() => props.history.push(props.documentPathBase)}
            />
          </div>
          <ReaderFooter
            currentPage={currentPage}
            docId={doc.id}
            isDocumentLoadError={isDocumentLoadError}
            numPages={numPages}
            setCurrentPage={() => setCurrentPage()}
            showPdf={props.showPdf}
          />
        </div>
        {showSideBar && (
          <ReaderSidebar
            doc={doc}
            showSideBar={showSideBar}
            toggleSideBar={() => dispatch(togglePdfSidebar())}
            vacolsId={props.match.params.vacolsId}
          />
        )}
        <DeleteModal documentId={currentDocumentId} />
        <ShareModal />
      </div>
    </>
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
  onZoomChange: PropTypes.func,
  progressBarOptions: PropTypes.object,
};

export default DocumentViewer;
