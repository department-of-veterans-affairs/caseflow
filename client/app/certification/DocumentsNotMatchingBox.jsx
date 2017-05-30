import React from 'react';

// TODO: refactor to use shared components where necessary
const DocumentsNotMatchingBox = () => {
  return <div className="usa-alert usa-alert-error cf-app-segment" role="alert">
    <div className="usa-alert-body">
      <h3 className="usa-alert-heading">Some documents could not be found in VBMS.</h3>
    </div>
  </div>;
};

export default DocumentsNotMatchingBox;
