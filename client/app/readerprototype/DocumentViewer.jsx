import React, { useState } from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import PdfDocument from './PdfDocument';
import ReaderToolbar from './ReaderToolbar';
import ReaderSidebar from './ReaderSidebar';
import ReaderFooter from './ReaderFooter';

const ZOOM_LEVEL_MIN = 20;
const ZOOM_LEVEL_MAX = 300;
const ZOOM_INCREMENT = 20;

const selectedDocIndex = (props) => {
  const selectedDocId = Number(props.match.params.docId);

  return _.findIndex(props.allDocuments, { id: selectedDocId });
};

const selectedDoc = (props) => (
  props.allDocuments[selectedDocIndex(props)]
);

const getPrevDoc = (props) => _.get(props.allDocuments, [selectedDocIndex(props) - 1]);
const getNextDoc = (props) => _.get(props.allDocuments, [selectedDocIndex(props) + 1]);

const getPrevDocId = (props) => _.get(getPrevDoc(props), 'id');
const getNextDocId = (props) => _.get(getNextDoc(props), 'id');

const DocumentViewer = (props) => {
  const [currentPage, setCurrentPage] = useState(0);
  const [zoomLevel, setZoomLevel] = useState(100);

  const doc = selectedDoc(props);

  const getPageCount = () => {
    //while !document.getElementById('pdfContainer') show loading
    if (document.getElementById('pdfContainer')) {
      return document.getElementById('pdfContainer').childElementCount;
    }
  };

  const pdfDocumentStyle = css({
    position: 'relative',
    width: '100%',
    height: '100%',
  });

  return (
    <div>
      <div className="cf-pdf-page-container">
        <ReaderSidebar
          doc={doc}
        />
        <div className="cf-pdf-container">
          <div className="cf-pdf-header cf-pdf-toolbar headerPrototype">
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
            />
          </div>
          <div>
            <div className="cf-search-bar hidden"></div>
            <div className="cf-pdf-scroll-view">
              <div
                id={`${doc.content_url}`}
                {...pdfDocumentStyle} >
                <PdfDocument
                  key={`${doc.content_url}`}
                  fileUrl={`${doc.content_url}`}
                  zoomLevel={`${zoomLevel}`}
                />
              </div>
            </div>
          </div>
          <ReaderFooter
            selectedDocIndex={selectedDocIndex(props)}
            docCount={props.allDocuments.length}
            prevDocId={getPrevDocId(props)}
            nextDocId={getNextDocId(props)}
            showPreviousDocument={props.showPdf(getPrevDocId(props))}
            showNextDocument={props.showPdf(getNextDocId(props))}
            pageCount={getPageCount()}
          />
        </div>
        <div className="cf-sidebar-wrapper">
        </div>
      </div>
    </div>
  );
};

DocumentViewer.propTypes = {
  allDocuments: PropTypes.array.isRequired,
  showPdf: PropTypes.func,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  documentPathBase: PropTypes.string,
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    receivedAt: PropTypes.string,
    type: PropTypes.string
  }).isRequired,
};

export default DocumentViewer;
