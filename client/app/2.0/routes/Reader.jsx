// External Dependencies
import React from 'react';

// Internal Dependencies
const DocumentsTable = React.lazy(() => import('app/2.0/screens/reader/DocumentsTable'));
const Document = React.lazy(() => import('app/2.0/screens/reader/Document'));

const ReaderRoutes = (props) => {
  return (
    <React.Fragment>
      <DocumentsTable {...props} />
      <Document {...props} />
    </React.Fragment>
  );
};

export default ReaderRoutes;

