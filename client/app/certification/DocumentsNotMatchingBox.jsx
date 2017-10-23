import React from 'react';
import Alert from '../components/Alert';

// TODO: refactor to use shared components where necessary
const DocumentsNotMatchingBox = () =>
  <Alert
    title="Some documents could not be found in VBMS."
    type="error" />;

export default DocumentsNotMatchingBox;
