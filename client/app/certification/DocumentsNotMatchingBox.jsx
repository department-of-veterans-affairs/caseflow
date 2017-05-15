import React from 'react';

// TODO: refactor to use shared components where necessary
const DocumentsNotMatchingBox = () => {
  return <div className="usa-alert usa-alert-error cf-app-segment" role="alert">
    <div className="usa-alert-body">
      <h3 className="usa-alert-heading">Cannot find documents in VBMS</h3>
      <p className="usa-alert-text">
        Some of the files listed in VACOLS could not be found in VBMS.
      </p>
    </div>
  </div>;
};

export default DocumentsNotMatchingBox;
