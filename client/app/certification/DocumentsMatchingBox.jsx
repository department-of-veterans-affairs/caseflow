import React from 'react';

// TODO: refactor to use shared components if helpful
const DocumentsMatchingBox = () => {
  return <div className="usa-alert cf-app-segment usa-alert-success">
    <div className="usa-alert-body">
      <h3 className="usa-alert-heading">All documents detected! </h3>
      <p className="usa-alert-text">
        The Form 9, NOD, SOC, and SSOCs (if applicable) were found in the eFolder.
      </p>
    </div>
  </div>;
};

export default DocumentsMatchingBox;
