import React from 'react';
import Alert from '../components/Alert';

// TODO: refactor to use shared components if helpful
const DocumentsMatchingBox = ({ areDatesExactlyMatching }) =>
  <Alert
    title="All documents found with matching VBMS and VACOLS dates."
    type="success">
    {!areDatesExactlyMatching &&
        'SOC and SSOC dates in VBMS can be up to 4 days before the VACOLS date to be considered matching.'}
  </Alert>;

export default DocumentsMatchingBox;
