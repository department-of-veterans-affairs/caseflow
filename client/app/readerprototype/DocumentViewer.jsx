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
import { fetchAppealDetails } from '../reader/PdfViewer/PdfViewerActions';
import DeleteModal from './components/Comments/DeleteModal';
import ShareModal from './components/Comments/ShareModal';
import { getNextDocId, getPrevDocId, getRotationDeg, selectedDoc, selectedDocIndex } from './util/documentUtil';

const ZOOM_LEVEL_MIN = 20;
const ZOOM_LEVEL_MAX = 300;
const ZOOM_INCREMENT = 20;

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [numPages, setNumPages] = useState(null);
  const [rotateDeg, setRotateDeg] = useState('0deg');
  const [showSearchBar, setShowSearchBar] = useState(false);
  const [showSideBar, setShowSideBar] = useState(true);
  const [zoomLevel, setZoomLevel] = useState(100);
  const dispatch = useDispatch();

  const currentDocumentId = Number(props.match.params.docId);
  // const appeal = () => dispatch(fetchAppealDetails(props.match.params.vacolsId))();

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

  const doc = selectedDoc(props);

  const getPageNumFromScrollTop = (event) => {
    const { clientHeight, scrollTop, scrollHeight } = event.target;
    const pageHeightEstimate = rotateDeg === '90deg' || rotateDeg === '270deg' ? clientHeight : scrollHeight / numPages;
    const pageNumber = Math.floor((pageHeightEstimate + scrollTop) / pageHeightEstimate);

    if (pageNumber > numPages) {
      setCurrentPage(numPages);
    } else {
      setCurrentPage(pageNumber);
    }
  };

  document.body.style.overflow = 'hidden';

  return (
    <div id="prototype-reader" className="cf-pdf-page-container">
      <div className="prototype-reader-main">
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
            fileUrl={`${doc.content_url}`}
            key={`${doc.content_url}`}
            rotateDeg={rotateDeg}
            setNumPages={setNumPages}
            zoomLevel={`${zoomLevel}`}
            documentId={currentDocumentId}
          />
        </div>
        <ReaderFooter
          currentPage={currentPage}
          docCount={props.allDocuments.length}
          nextDocId={getNextDocId(props)}
          numPages={numPages}
          prevDocId={getPrevDocId(props)}
          setCurrentPage={() => setCurrentPage()}
          selectedDocIndex={selectedDocIndex(props)}
          showNextDocument={props.showPdf(getNextDocId(props))}
          showPreviousDocument={props.showPdf(getPrevDocId(props))}
        />
      </div>
      { showSideBar &&
          (
            <ReaderSidebar
              // appeal={appeal}
              doc={doc}
              documents={props.allDocuments}
              toggleSideBar={() => setShowSideBar(false)}
            />
          )
      }
      <DeleteModal documentId={currentDocumentId} />
      <ShareModal />
    </div>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.object,
  documentPathBase: PropTypes.string,
  showPdf: PropTypes.func,
  history: PropTypes.any,
};

export default DocumentViewer;
