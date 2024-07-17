import PropTypes from 'prop-types';
import React, { useState, useEffect } from 'react';

import PdfDocument from './components/PdfDocument';
import ReaderFooter from './components/ReaderFooter';
import ReaderSidebar from './components/ReaderSidebar';
import ReaderToolbar from './components/ReaderToolbar';
import ReaderSearchBar from './components/ReaderSearchBar';

import { getNextDocId, getPrevDocId, getRotationDeg, selectedDoc, selectedDocIndex } from './util/documentUtil';
import { docViewerStyles } from './util/layoutUtil';

const ZOOM_LEVEL_MIN = 20;
const ZOOM_LEVEL_MAX = 300;
const ZOOM_INCREMENT = 20;

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [numPages, setNumPages] = useState(null);
  const [rotateDeg, setRotateDeg] = useState('0deg');
  const [showSearchBar, setShowSearchBar] = useState(false);
  const [zoomLevel, setZoomLevel] = useState(100);

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
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, []);

  const doc = selectedDoc(props);

  const getPageNumFromScrollTop = (event) => {
    const { clientHeight, scrollTop, scrollHeight } = event.target;
    const pageHeightEstimate = (rotateDeg === '90deg' || rotateDeg === '270deg') ?
      clientHeight : (scrollHeight / numPages);
    const pageNumber = Math.floor((pageHeightEstimate + scrollTop) / pageHeightEstimate);

    if (pageNumber > numPages) {
      setCurrentPage(numPages);
    } else {
      setCurrentPage(pageNumber);
    }
  };

  document.body.style.overflow = 'hidden';

  return (
    <div>
      <div className="cf-pdf-page-container-prototype">
        <div className="sidebarContainer" {...docViewerStyles.sidebarContainer}>
          <ReaderSidebar
            doc={doc}
            documents={props.allDocuments}
          />
        </div>
        <div className="cf-pdf-container" {...docViewerStyles.documentContainer}>
          <div className="cf-pdf-toolbar-prototype">
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
              zoomLevel={zoomLevel}
            />
          </div>
          {showSearchBar && <ReaderSearchBar />}
          <div className="cf-pdf-scroll-view" onScroll={getPageNumFromScrollTop}>
            <PdfDocument
              fileUrl={`${doc.content_url}`}
              key={`${doc.content_url}`}
              rotateDeg={rotateDeg}
              setNumPages={setNumPages}
              zoomLevel={`${zoomLevel}`}
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
      </div>
    </div>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.array.isRequired,
  documentPathBase: PropTypes.string,
  showPdf: PropTypes.func
};

export default DocumentViewer;
