import React from 'react';
import PropTypes from 'prop-types';

const WorksheetFooter = ({ veteranName }) => (
  <div className="cf-print-footer">
    <div className="cf-push-right">
      <div>
        {veteranName},
        <span className="cf-print-number" />
      </div>
    </div>
  </div>
);

WorksheetFooter.propTypes = {
  veteranName: PropTypes.string.isRequired
};

export default WorksheetFooter;
