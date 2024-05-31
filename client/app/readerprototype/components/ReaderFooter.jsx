import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import { PageArrowLeftIcon } from '../../components/icons/PageArrowLeftIcon';
import { PageArrowRightIcon } from '../../components/icons/PageArrowRightIcon';

import { pdfToolbarStyles } from '../layoutUtil';
import { handleKeyPress } from '../documentUtil';

const ReaderFooter = ({
  docPageCount,
  prevDocId,
  nextDocId,
  showPreviousDocument,
  showNextDocument,
  selectedDocIndex,
  docCount,
}) => {
  const [currentPage, setCurrentPage] = useState(1);

  return (
    <div id="footerPrototype" className="cf-pdf-footer cf-pdf-toolbar" {...pdfToolbarStyles.footer}>

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
                  onChange={setCurrentPage}
                  onKeyPress={handleKeyPress}
                  value={currentPage}
                  required={false}
                  className={['page-progress-indicator-input']}
                  disabled
                />
              </div>
              of {docPageCount}
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
  docPageCount: PropTypes.number,
  selectedDocIndex: PropTypes.number,
  docCount: PropTypes.number,
  prevDocId: PropTypes.number,
  nextDocId: PropTypes.number,
  showPreviousDocument: PropTypes.func,
  showNextDocument: PropTypes.func,
};

export default ReaderFooter;
