import PropTypes from 'prop-types';
import React from 'react';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import { PageArrowLeftIcon } from '../../components/icons/PageArrowLeftIcon';
import { PageArrowRightIcon } from '../../components/icons/PageArrowRightIcon';

const ReaderFooter = ({
  currentPage,
  docCount,
  nextDocId,
  numPages,
  prevDocId,
  setCurrentPage,
  selectedDocIndex,
  showNextDocument,
  showPreviousDocument,
  disablePreviousNext,
}) => {
  const isValidInputPageNumber = (pageNumber) => {
    if (!isNaN(pageNumber) && pageNumber % 1 === 0) {

      return pageNumber >= 1 && pageNumber <= numPages;
    }
  };

  const sanitizedPageNumber = (pageNumberInput) => {
    let pageNumber = parseInt(pageNumberInput, 10);

    if (!pageNumber || !isValidInputPageNumber(pageNumber)) {
      return setCurrentPage;
    }

    return pageNumber;
  };

  const handleKeyPress = (event) => {
    if (event.key === 'Enter') {
      const newPageNumber = sanitizedPageNumber(event.target.value);

      setCurrentPage(newPageNumber);
      event.target.value = newPageNumber;
      if (setCurrentPage !== newPageNumber) {
        document.getElementById(`canvasWrapper-${newPageNumber}`).scrollIntoView();
      }
    }
  };

  return (
    <div id="prototype-footer" className="cf-pdf-footer cf-pdf-toolbar">
      <div className="cf-pdf-footer-buttons-left">
        {prevDocId && (
          <Button
            name="previous"
            classNames={['cf-pdf-button']}
            onClick={showPreviousDocument}
            ariaLabel="previous PDF"
            disabled={disablePreviousNext}
          >
            <PageArrowLeftIcon />
            <span className="left-button-label">Previous</span>
          </Button>
        )}
      </div>

      <div className="cf-pdf-buttons-center">
        <span>
          <span className="page-progress-indicator">
            <span>
              <div style={{ display: 'inline-flex' }}>
                <TextField
                  maxLength={4}
                  name="page-progress-indicator-input"
                  label="Page"
                  onChange={setCurrentPage}
                  onKeyPress={handleKeyPress}
                  value={currentPage}
                  required={false}
                  className={['prototype-page-progress-indicator-input']}
                />
              </div>
              of {numPages}
            </span>
          </span>
          |
        </span>
        <span className="doc-list-progress-indicator">
          Document {selectedDocIndex + 1} of {docCount}
        </span>
      </div>

      <div className="cf-pdf-footer-buttons-right">
        {nextDocId && (
          <Button
            name="next"
            classNames={['cf-pdf-button cf-right-side']}
            onClick={showNextDocument}
            ariaLabel="next PDF"
            disabled={disablePreviousNext}
          >
            <span className="right-button-label">Next</span>
            <PageArrowRightIcon />
          </Button>
        )}
      </div>
    </div>
  );
};

ReaderFooter.propTypes = {
  currentPage: PropTypes.number,
  docCount: PropTypes.number,
  nextDocId: PropTypes.number,
  numPages: PropTypes.number,
  prevDocId: PropTypes.number,
  setCurrentPage: PropTypes.func,
  selectedDocIndex: PropTypes.number,
  showNextDocument: PropTypes.func,
  showPreviousDocument: PropTypes.func,
  disablePreviousNext: PropTypes.bool,
};

export default ReaderFooter;
