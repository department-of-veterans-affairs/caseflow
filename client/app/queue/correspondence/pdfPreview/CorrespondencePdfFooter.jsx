// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import NumberField from '../../../components/NumberField';

/**
 * Document Footer displays the PDF footer controls
 * @param {Object} pdfDocProxy - Information about the pdf document
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
              <div id="pdf-preview-footer-input-field">
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
  currentPage: PropTypes.number,
  handleSetCurrentPage: PropTypes.func,
  pdfDocProxy: PropTypes.object,
};

