// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

const DocumentsTable = () => (
  <React.Fragment />
);

DocumentsTable.propTypes = {
  appeal: PropTypes.object,
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  singleDocumentMode: PropTypes.bool,

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  setCategoryFilter: PropTypes.func
};

export default DocumentsTable;
