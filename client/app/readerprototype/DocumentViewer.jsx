import React, { useState } from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';

import PdfDocument from './PdfDocument';
import ReaderToolbar from './ReaderToolbar';
import ReaderSidebar from './ReaderSidebar';
import ReaderFooter from './ReaderFooter';

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
  const [pageNumber, setPageNumber] = useState(1);
  const [zoomLevel, setZoomLevel] = useState('100%');

  const doc = selectedDoc(props);

  const pdfDocumentStyle = css({
    position: 'relative',
    width: '100%',
    height: '100%',
    // zoom:  {zoomLevel }
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
                />
              </div>
            </div>
          </div>
          <ReaderFooter
            selectedDocNumber={selectedDocIndex(props)}
            docCount={props.allDocuments.length}
            prevDocId={getPrevDocId(props)}
            nextDocId={getNextDocId(props)}
            showPreviousDocument={props.showPdf(getPrevDocId(props))}
            showNextDocument={props.showPdf(getNextDocId(props))}
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
