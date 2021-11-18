// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { toolbarStyles } from 'styles/reader/Document/PDF';
import Button from 'app/components/Button';
import TextField from 'app/components/TextField';
import {
  FilterIcon,
  PageArrowLeft,
  PageArrowRight,
} from 'app/components/RenderFunctions';

/**
 * Document Footer displays the PDF footer controls
 * @param {Object} props -- Contains details about the current and previous documents
 */
export const DocumentFooter = ({
  currentIndex,
  prevDocId,
  nextDocId,
  loadError,
  docsFiltered,
  filteredDocIds,
  nextDoc,
  prevDoc,
  doc,
  setPageNumber,
  handleKeyPress,
}) => (
  <div className="cf-pdf-footer cf-pdf-toolbar" {...toolbarStyles.footer}>
    <div className="cf-pdf-footer-buttons-left">
      {prevDocId !== 0 && (
        <Button
          id="button-previous"
          name="previous"
          classNames={['cf-pdf-button']}
          onClick={prevDoc}
          ariaLabel="previous PDF"
        >
          <PageArrowLeft />
          <span className="left-button-label">Previous</span>
        </Button>
      )}
    </div>
    <div className="cf-pdf-buttons-center">
      {!loadError && (
        <span>
          <span className="page-progress-indicator">
            {doc.numPages ? (
              <span>
                <div style={{ display: 'inline-block' }}>
                  <TextField
                    maxLength={4}
                    name="page-progress-indicator-input"
                    label="Page"
                    onChange={setPageNumber}
                    onKeyPress={handleKeyPress}
                    value={doc.currentPage}
                    required={false}
                    className={['page-progress-indicator-input']}
                  />
                </div>
                of {doc.numPages}
              </span>
            ) : (
              <em>Loading document...</em>
            )}
          </span>
          |
        </span>
      )}
      <span className="doc-list-progress-indicator">
        {docsFiltered && <FilterIcon />}
        Document {currentIndex + 1} of {filteredDocIds.length}
      </span>
    </div>
    <div className="cf-pdf-footer-buttons-right">
      {nextDocId !== 0 && (
        <Button
          id="button-next"
          name="next"
          classNames={['cf-pdf-button cf-right-side']}
          onClick={nextDoc}
          ariaLabel="next PDF"
        >
          <span className="right-button-label">Next</span>
          <PageArrowRight />
        </Button>
      )}
    </div>
  </div>
);

DocumentFooter.propTypes = {
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
  doc: PropTypes.object,
};
