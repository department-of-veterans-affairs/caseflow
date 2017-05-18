import React from 'react';

// TODO: refactor to use shared components if helpful
const DocumentsMatchingBox = () => {
  return <div className="usa-alert cf-app-segment usa-alert-success">
    <div className="usa-alert-body">
      <h3 className="usa-alert-heading">Matching documents found in VBMS for all VACOLS documents.</h3>
      <p className="usa-alert-text">
        A VBMS document date is considered matching if it's within 4 days before the VACOLS date.
      </p>
    </div>
  </div>;
};

export default DocumentsMatchingBox;
