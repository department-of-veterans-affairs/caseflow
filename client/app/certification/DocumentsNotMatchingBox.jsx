import React from 'react';
import AlertBanner from '../components/AlertBanner';

// TODO: refactor to use shared components where necessary
const DocumentsNotMatchingBox = () =>
    <AlertBanner
      title="Some documents could not be found in VBMS."
      type="error" />;

export default DocumentsNotMatchingBox;
