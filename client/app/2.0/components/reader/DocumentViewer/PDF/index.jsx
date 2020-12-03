// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import { File } from 'components/reader/DocumentViewer/PDF/File';
import { pdfStyles, fileContainerStyles } from 'styles/reader/Document/Pdf';
import StatusMessage from 'app/components/StatusMessage';

/**
 * PDF Container for the Document view
 * @param {Object} props -- Contains PDF file and file list and functions to change
 */
export const Pdf = ({ doc, clickPage, ...props }) => (
  <div className="cf-pdf-scroll-view">
    <div id={doc.content_url} style={fileContainerStyles} onClick={clickPage}>
      {doc.loadError ? (
        <div>
          <div style={pdfStyles} >
            <StatusMessage title="Unable to load document" type="warning">
              Caseflow is experiencing technical difficulties and cannot load <strong>{doc.type}</strong>.
              <br />
              You can try <a href={`${doc.content_url}?type=${doc.type}&download=true`}>downloading the document</a>
              or try again later.
            </StatusMessage>
          </div>
        </div>
      ) : (
        <File
          key={`${doc.content_url}`}
          file={doc.content_url}
          documentType={doc.type}
          currentDocument={doc}
          {...props}
        />
      )}
    </div>
  </div>
);

Pdf.propTypes = {
  doc: PropTypes.object,
  files: PropTypes.array,
  documentType: PropTypes.string,
  loadError: PropTypes.string,
  clickPage: PropTypes.func
};
