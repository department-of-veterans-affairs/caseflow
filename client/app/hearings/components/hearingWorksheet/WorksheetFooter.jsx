import React from 'react';
import PropTypes from 'prop-types';

const WorksheetFooter = ({ veteranName }) => (
  <div className="cf-print-footer">
    <div>
      {veteranName}
    </div>
  </div>
);

WorksheetFooter.propTypes = {
  veteranName: PropTypes.string.isRequired
};

export default WorksheetFooter;
