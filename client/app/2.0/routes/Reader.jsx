// External Dependencies
import React from 'react';
import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';

// Internal Dependencies
import { getClaimsFolderPageTitle } from 'app/2.0/utils';

// Lazy load screens
const DocumentsTable = React.lazy(() => import('app/2.0/screens/reader/DocumentsTable'));
const Document = React.lazy(() => import('app/2.0/screens/reader/Document'));

const ReaderRoutes = ({ appeal }) => (
  <React.Fragment>
    <Route
      exact
      title={getClaimsFolderPageTitle(appeal)}
      breadcrumb="Reader"
      path="/reader/appeal/:vacolsId/documents"
      render={(props) => <DocumentsTable {...props} />}
    />
    <Route
      exact
      title="Document Viewer | Caseflow Reader"
      breadcrumb="Document Viewer"
      path="/reader/appeal/:vacolsId/documents/:docId"
      render={(props) => <Document {...props} />}
    />
  </React.Fragment>
);

ReaderRoutes.propTypes = {
  appeal: PropTypes.object
};

export default ReaderRoutes;
