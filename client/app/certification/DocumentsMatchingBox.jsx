import React from 'react';
import AlertBanner from '../components/AlertBanner';

// TODO: refactor to use shared components if helpful
const DocumentsMatchingBox = ({ areDatesExactlyMatching }) => {

  return <div>
    <AlertBanner
      title="All documents found with matching VBMS and VACOLS dates."
      type="success">
      {!areDatesExactlyMatching &&
        'SOC and SSOC dates in VBMS can be up to 4 days before the VACOLS date to be considered matching.'}
    </AlertBanner>
  </div>;
};

export default DocumentsMatchingBox;
