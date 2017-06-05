import React from 'react';

// TODO: refactor to use shared components if helpful
const DocumentsMatchingBox = ({ areDatesExactlyMatching }) => {

  return <div className="usa-alert cf-app-segment usa-alert-success">
            <div className="usa-alert-body">
              <h3 className="usa-alert-heading">All documents found with matching VBMS and VACOLS dates.</h3>
              {!areDatesExactlyMatching && <p className="usa-alert-text">
                SOC and SSOC dates in VBMS can be up to 4 days before the VACOLS date to be considered matching.
                </p>}
            </div>
          </div>;
};

export default DocumentsMatchingBox;
