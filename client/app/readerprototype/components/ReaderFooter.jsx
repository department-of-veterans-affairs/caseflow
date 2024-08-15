import PropTypes from 'prop-types';
import React from 'react';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import { PageArrowLeftIcon } from '../../components/icons/PageArrowLeftIcon';
import { PageArrowRightIcon } from '../../components/icons/PageArrowRightIcon';

const isValidWholeNumber = (pageNumber) => {
  return /^\d+$/.test(pageNumber);
};

const validatePageNum = (pageNumber, numPages) => {
  if (isValidWholeNumber(pageNumber)) {
    return parseInt(pageNumber, 10) >= 1 && parseInt(pageNumber, 10) <= numPages;
  }

  return false;
};

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
  const handleKeyPress = (event) => {
    if (event.key === 'Enter') {
      const targetPage = event.target.value;

      if (validatePageNum(targetPage, numPages)) {
        document.getElementById(`canvas-${targetPage}`).scrollIntoView();
        setCurrentPage(targetPage);
      } else if (currentPage) {
        event.target.value = currentPage;
      }
    } else if (validatePageNum(event.currentTarget?.value, numPages)) {
      setCurrentPage(event.currentTarget.value);
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
            <span> Page </span>
            <span>
              <div className="prototype-page-number-input">
                <TextField
                  name=""
                  label=""
                  maxLength={4}
                  onChange={handleKeyPress}
                  onKeyPress={handleKeyPress}
                  defaultValue={currentPage}
                  required={false}
                  className={['page-progress-indicator-input']}
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
