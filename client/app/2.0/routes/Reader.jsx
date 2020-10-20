// External Dependencies
import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

// Internal Dependencies
import PageRoute from 'app/components/PageRoute';
import { getClaimsFolderPageTitle, setAppeal } from 'app/2.0/utils';

// Lazy load screens
const DocumentsTable = React.lazy(() => import('app/2.0/screens/reader/DocumentsTable'));
const Document = React.lazy(() => import('app/2.0/screens/reader/Document'));

const ReaderRoutes = ({ appeal }) => (
  <React.Fragment>
    <PageRoute
      exact
      title={getClaimsFolderPageTitle(appeal)}
      breadcrumb="Reader"
      path="/:vacolsId/documents"
      render={DocumentsTable}
    />
    <PageRoute
      exact
      title="Document Viewer | Caseflow Reader"
      breadcrumb="Document Viewer"
      path="/:vacolsId/documents/:docId"
      render={Document}
    />
  </React.Fragment>
);

ReaderRoutes.propTypes = {
  appeal: PropTypes.object
};

const mapStateToProps = (state, props) => ({
  appeal: setAppeal(state, props)
});

export default connect(
  mapStateToProps,
  null
)(ReaderRoutes);

