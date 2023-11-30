// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import NumberField from '../../../components/NumberField';

/**
 * Document Footer displays the PDF footer controls
 * @param {Object} props -- Contains details about the current and previous documents
 */
export const CorrespondencePdfFooter = ({
  currentPage,
  pdfDocProxy,
  handleSetCurrentPage
}) => {
  return (
    <div className="cf-pdf-footer cf-pdf-toolbar">
      <div className="cf-pdf-buttons-center">
        <span className="page-progress-indicator">
          {pdfDocProxy.numPages ? (
            <>
              <div id="pdf-preview-footer-input-field" style={{ display: 'inline-block' }}>
                <NumberField
                  maxLength={4}
                  name="page-progress-indicator-input"
                  label="Page"
                  onChange={handleSetCurrentPage}
                  value={currentPage}
                  required={false}
                  className={['page-progress-indicator-input']}
                />
              </div>
              of {pdfDocProxy.numPages}
            </>
          ) : (
            <em>Loading document...</em>
          )}
        </span>
      </div>
    </div>
  );
};

CorrespondencePdfFooter.propTypes = {
  currentIndex: PropTypes.number,
  prevDocId: PropTypes.number,
  nextDocId: PropTypes.number,
  loadError: PropTypes.string,
  docsFiltered: PropTypes.bool,
  filteredDocIds: PropTypes.array,
  nextDoc: PropTypes.func,
  prevDoc: PropTypes.func,
  numPages: PropTypes.number,
  setPageNumber: PropTypes.func,
  handleKeyPress: PropTypes.func,
  pageNumber: PropTypes.number,
  pdfDocProxy: PropTypes.object,
};

