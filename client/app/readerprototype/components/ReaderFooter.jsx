import PropTypes from 'prop-types';
import React, { useEffect } from 'react';
import { useSelector } from 'react-redux';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import { FilterNoOutlineIcon } from '../../components/icons/FilterNoOutlineIcon';
import { PageArrowLeftIcon } from '../../components/icons/PageArrowLeftIcon';
import { PageArrowRightIcon } from '../../components/icons/PageArrowRightIcon';
import { docListIsFiltered, getFilteredDocIds } from '../../reader/selectors';
import { annotationPlacement } from '../selectors';

const ReaderFooter = ({
  currentPage,
  docId,
  numPages,
  setCurrentPage,
  showPdf,
}) => {
  const { isPlacingAnnotation } = useSelector(annotationPlacement);

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

  const isDocListFiltered = useSelector((state) => docListIsFiltered(state));

  const filteredDocIds = useSelector(getFilteredDocIds);
  const currentDocIndex = filteredDocIds.indexOf(docId);
  const getPrevDocId = () => filteredDocIds?.[currentDocIndex - 1];
  const getNextDocId = () => filteredDocIds?.[currentDocIndex + 1];

  useEffect(() => {
    const keyHandler = (event) => {
      if (event.key === 'ArrowLeft' && !isPlacingAnnotation) {
        showPdf(getPrevDocId())();
      }
      if (event.key === 'ArrowRight' && !isPlacingAnnotation) {
        showPdf(getNextDocId())();
      }
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, [currentDocIndex, isPlacingAnnotation]);

  return (
    <div id="prototype-footer" className="cf-pdf-footer cf-pdf-toolbar">
      <div className="cf-pdf-footer-buttons-left">
        {getPrevDocId() && (
          <Button
            name="previous"
            classNames={['cf-pdf-button']}
            onClick={showPdf(getPrevDocId())}
            ariaLabel="previous PDF"
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
          { isDocListFiltered && <FilterNoOutlineIcon /> } Document {currentDocIndex + 1} of {filteredDocIds.length}
        </span>
      </div>

      <div className="cf-pdf-footer-buttons-right">
        {getNextDocId() && (
          <Button
            name="next"
            classNames={['cf-pdf-button cf-right-side']}
            onClick={showPdf(getNextDocId())}
            ariaLabel="next PDF"
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
  docId: PropTypes.number,
  numPages: PropTypes.number,
  setCurrentPage: PropTypes.func,
  showPdf: PropTypes.func,
};

export default ReaderFooter;
