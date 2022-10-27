// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { RightTriangleIcon } from 'app/components/icons/RightTriangleIcon';

/**
 * Last Read Document Indicator component
 * @param {Object} props -- Contains the React ref and details about the last read document
 */
export const LastReadIndicator = ({ lastReadRef, documentList, docId }) =>
  documentList.pdfList.lastReadDocId === docId && (
    <span
      id="read-indicator"
      ref={lastReadRef}
      aria-label="Most recently read document indicator">
      <RightTriangleIcon />
    </span>
  );

LastReadIndicator.propTypes = {
  lastReadRef: PropTypes.element,
  documentList: PropTypes.object,
  docId: PropTypes.number
};
