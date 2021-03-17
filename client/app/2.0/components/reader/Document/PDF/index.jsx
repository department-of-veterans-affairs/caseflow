// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import { File } from 'components/reader/Document/PDF/File';
import { pdfStyles, fileContainerStyles } from 'styles/reader/Document/PDF';
import StatusMessage from 'app/components/StatusMessage';

/**
 * PDF Container for the Document view
 * @param {Object} props -- Contains PDF file and file list and functions to change
 */
export const PDF = ({ file, files, loadError, documentType, ...props }) => (
  <div className="cf-pdf-scroll-view">
    <div id={file} style={fileContainerStyles}>
      {files.map((pdf) => loadError ? (
        <div>
          <div style={pdfStyles} >
            <StatusMessage title="Unable to load document" type="warning">
              Caseflow is experiencing technical difficulties and cannot load <strong>{documentType}</strong>.
              <br />
              You can try <a href={`${file}?type=${documentType}&download=true`}>downloading the document</a>
              or try again later.
            </StatusMessage>
          </div>
        </div>
      ) : (
        <File
          key={`${file}`}
          file={file}
          isVisible={pdf === file}
          documentType={documentType}
          {...props}
        />
      ))}
    </div>
  </div>
);

PDF.propTypes = {
  file: PropTypes.object,
  files: PropTypes.array,
  documentType: PropTypes.string,
  loadError: PropTypes.string
};
