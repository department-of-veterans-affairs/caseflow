import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';

import PdfDocument from './components/PdfDocument';
import ReaderFooter from './components/ReaderFooter';
import ReaderSearchBar from './components/ReaderSearchBar';
import ReaderSidebar from './components/ReaderSidebar';
import ReaderToolbar from './components/ReaderToolbar';

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
  const currentDocumentId = Number(props.match.params.docId);

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
    <div id="readerPrototype">
      <div className="cf-readerpro-container">
        <div className="cf-readerpro-pdf-container">
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
            setShowSideBar={() => setShowSideBar(true)}
            zoomLevel={zoomLevel}
          />
          {showSearchBar && <ReaderSearchBar />}
          <PdfDocument
            fileUrl={`${doc.content_url}`}
            key={`${doc.content_url}`}
            rotateDeg={rotateDeg}
            setNumPages={setNumPages}
            zoomLevel={`${zoomLevel}`}
            documentId={currentDocumentId}
            onScroll={getPageNumFromScrollTop}
          />
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
              doc={doc}
              documents={props.allDocuments}
              showSideBar={showSideBar}
              setShowSideBar={() => setShowSideBar(false)}

            />
          )
        }
      </div>
      <DeleteModal documentId={currentDocumentId} />
      <ShareModal />
    </div>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.array.isRequired,
  documentPathBase: PropTypes.string,
  showPdf: PropTypes.func,
};

export default DocumentViewer;
