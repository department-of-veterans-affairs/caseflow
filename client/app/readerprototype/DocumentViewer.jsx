import PropTypes from 'prop-types';
import React, { useState } from 'react';

import PdfDocument from './components/PdfDocument';
import ReaderFooter from './components/ReaderFooter';
import ReaderSidebar from './components/ReaderSidebar';
import ReaderToolbar from './components/ReaderToolbar';

import { getNextDocId, getPrevDocId, selectedDoc, selectedDocIndex, getRotationDeg } from './util/documentUtil';
import { docViewerStyles, pdfDocumentStyles } from './util/layoutUtil';

const ZOOM_LEVEL_MIN = 20;
const ZOOM_LEVEL_MAX = 300;
const ZOOM_INCREMENT = 20;

const DocumentViewer = (props) => {
  const [zoomLevel, setZoomLevel] = useState(100);
  const [rotateDeg, setRotateDeg] = useState('0deg');

  const doc = selectedDoc(props);

  document.body.style.overflow = 'hidden';

  return (
    <div>
      <div className="cf-pdf-page-container-prototype">
        <div className="sidebarContainer" {...docViewerStyles.sidebarContainer}>
          <ReaderSidebar
            doc={doc}
          />
        </div>
        <div className="cf-pdf-container" {...docViewerStyles.documentContainer}>
          <div className="cf-pdf-toolbar-prototype">
            <ReaderToolbar
              documentPathBase={props.documentPathBase}
              doc={doc}
              showClaimsFolderNavigation={props.allDocuments.length > 1}
              resetZoomLevel={() => setZoomLevel(100)}
              setZoomInLevel={() => setZoomLevel(zoomLevel + ZOOM_INCREMENT)}
              disableZoomIn={zoomLevel === ZOOM_LEVEL_MAX}
              setZoomOutLevel={() => setZoomLevel(zoomLevel - ZOOM_INCREMENT)}
              disableZoomOut={zoomLevel === ZOOM_LEVEL_MIN}
              zoomLevel={zoomLevel}
              rotateDocument={() => setRotateDeg(getRotationDeg(rotateDeg))}
              rotateDeg={`${rotateDeg}`}
            />
          </div>
          <div className="cf-search-bar hidden"></div>
          <div className="cf-pdf-scroll-view">
            <PdfDocument
              key={`${doc.content_url}`}
              fileUrl={`${doc.content_url}`}
              zoomLevel={`${zoomLevel}`}
              rotateDeg={rotateDeg}
            />
          </div>
          <ReaderFooter
            selectedDocIndex={selectedDocIndex(props)}
            docCount={props.allDocuments.length}
            prevDocId={getPrevDocId(props)}
            nextDocId={getNextDocId(props)}
            showPreviousDocument={props.showPdf(getPrevDocId(props))}
            showNextDocument={props.showPdf(getNextDocId(props))}
            // pageCount={getPageCount()}
          />
        </div>
      </div>
    </div>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.array.isRequired,
  showPdf: PropTypes.func,
  documentPathBase: PropTypes.string
};

export default DocumentViewer;
