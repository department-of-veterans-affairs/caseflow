import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import Button from '../components/Button';
import Link from '../components/Link';
import TextField from '../components/TextField';
import { PageArrowLeftIcon } from '../components/icons/PageArrowLeftIcon';
import { PageArrowRightIcon } from '../components/icons/PageArrowRightIcon';

const pdfWrapperSmall = 1165;
const ENTER_KEY = 'Enter';
const RADIX = 10;

const pdfToolbarStyles = {
  footer: css({
    position: 'absolute',
    bottom: 0,
    display: 'flex',
    alignItems: 'center',
    '&&': { [`@media(max-width:${pdfWrapperSmall}px)`]: {
      '& .left-button-label': { display: 'none' },
      '& .right-button-label': { display: 'none' }
    } }
  })
};

export const isValidWholeNumber = (number) => {
  return !isNaN(number) && number % 1 === 0;
};

const validatePageNum = (pageNumber) => {
  let pageNum = parseInt(pageNumber, RADIX);

  if (!pageNum || !isValidWholeNumber(pageNum) ||
    (pageNum < 1 || pageNum > this.props.numPages)) {
    return this.props.currentPage;
  }

  return pageNum;
};


const handleKeyPress = (event) => {
  // if (event.key === ENTER_KEY) {
  //   const pageNumber = event.target.value;
  //   const newPageNumber = validatePageNum(pageNumber);

  //   setPageNumber(newPageNumber);

  //   if (props.currentPage !== newPageNumber) {
  //     props.jumpToPage(newPageNumber, this.props.docId);
  //   }
  // }
};

const ReaderFooter = ({
  pageCount,
  prevDocId,
  nextDocId,
  showPreviousDocument,
  showNextDocument,
  selectedDocIndex,
  docCount,
}) => {
  return (
    <div className="cf-pdf-footer cf-pdf-toolbar" {...pdfToolbarStyles.footer}>

      <div className="cf-pdf-footer-buttons-left">
        {prevDocId && (
          <Button
            name="previous"
            classNames={['cf-pdf-button']}
            onClick={showPreviousDocument}
            ariaLabel="previous PDF">
            <PageArrowLeftIcon /><span className="left-button-label">Previous</span>
          </Button>
        )}
      </div>

      <div className="cf-pdf-buttons-center">
        <span>
          <span className="page-progress-indicator">
            <span> Page </span>
            <span>
              <div className="pageNumberInputPrototype">
                <TextField
                  name=""
                  label=""
                  maxLength={4}
                  // onChange={setPageNumber}
                  onKeyPress={handleKeyPress}
                  // value={getPageNumber}
                  required={false}
                  className={['page-progress-indicator-input']}
                />
              </div>
              of {pageCount}
            </span>
          </span>|
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
            ariaLabel="next PDF">
            <span className="right-button-label">Next</span><PageArrowRightIcon />
          </Button>
        )}
      </div>
    </div>
  );
};

ReaderFooter.propTypes = {
  pageCount: PropTypes.number,
  selectedDocIndex: PropTypes.number,
  docCount: PropTypes.number,
  prevDocId: PropTypes.number,
  nextDocId: PropTypes.number,
  showPreviousDocument: PropTypes.func,
  showNextDocument: PropTypes.func,
};

export default ReaderFooter;
