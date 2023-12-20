import React from 'react';
import PropTypes from 'prop-types';

import { sprintf } from 'sprintf-js';

export const MTVTaskHeader = ({ title, appeal, task }) => {
  return (
    <React.Fragment>
      <h1>{sprintf(title, appeal.veteranFullName)}</h1>

      <div className="case-meta">
        <span>
          <strong>Veteran ID:</strong> {appeal.veteranFileNumber}
        </span>
        <span style={{ marginLeft: '3rem' }}>
          <strong>Task:</strong> {task.label}
        </span>
      </div>
      <div className="cf-help-divider" style={{ margin: '15px 0' }} />
    </React.Fragment>
  );
};

MTVTaskHeader.propTypes = {
  title: PropTypes.string,
  appeal: PropTypes.object,
  task: PropTypes.object
};

MTVTaskHeader.defaultProps = {
  title: "Review %s's Motion to Vacate"
};
