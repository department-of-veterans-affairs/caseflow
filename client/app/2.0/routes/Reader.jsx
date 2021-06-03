// External Dependencies
import React from 'react';
// import { Route } from 'react-router-dom';
import PropTypes from 'prop-types';

// Internal Dependencies
import PageRoute from 'app/components/PageRoute';
import AppFrame from 'app/components/AppFrame';
import { claimsFolderPageTitle } from 'utils';
import { LOADING_DATA_MESSAGE } from 'store/constants/reader';
import { useSelector } from 'react-redux';
import BaseLayout from 'layouts/BaseLayout';

// Lazy load screens
const DocumentList = React.lazy(() => import('screens/reader/DocumentList'));
const DocumentViewer = React.lazy(() => import('screens/reader/DocumentViewer'));

const ReaderRoutes = (props) => {
  // Override The App Name here for the page routes
  const appName = 'Reader';

  // Get the Reader Loading Status
  const { loading } = useSelector((state) => ({
    loading: state.reader.documentList.loading
  }));

  // Return the list of routes
  return (
    <AppFrame wideApp>
      <BaseLayout appName={appName} {...props}>
        <PageRoute
          exact
          loading={loading}
          loadingMessage={LOADING_DATA_MESSAGE}
          title={claimsFolderPageTitle(props.appeal)}
          path="/reader/appeal/:vacolsId/documents"
          breadcrumb="Reader"
          render={(routeProps) => <DocumentList {...props} {...routeProps} />}
          appName={appName}
        />
        <PageRoute
          exact
          loading={loading}
          loadingMessage={LOADING_DATA_MESSAGE}
          title="Document Viewer | Caseflow Reader"
          path="/reader/appeal/:vacolsId/documents/:docId"
          breadcrumb="Document Viewer"
          render={(routeProps) => (
            <DocumentViewer
              {...props}
              {...routeProps}
              documentPathBase={`/reader/appeal/${ routeProps.match.params.vacolsId }/documents`}
            />
          )}
          appName={appName}
        />
      </BaseLayout>
    </AppFrame>
  );
};

ReaderRoutes.propTypes = {
  appeal: PropTypes.object
};

export default ReaderRoutes;
