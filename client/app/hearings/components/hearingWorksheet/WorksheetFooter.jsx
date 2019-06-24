import React from 'react';
import PropTypes from 'prop-types';

const WorksheetFooter = ({ veteranName }) => (
  <div className="cf-print-footer">
    <div>
      {veteranName},
      <span className="cf-print-number" />
    </div>
  </div>
);

WorksheetFooter.propTypes = {
  veteranName: PropTypes.string.isRequired
};

export default WorksheetFooter;
