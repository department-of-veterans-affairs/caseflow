// External Dependencies
import React from 'react';
import { Route } from 'react-router-dom';
// Internal Dependencies
import Loadable from 'app/2.0/components/shared/Loadable';

// Lazy Load screens
const DecisionReviewer = React.lazy(() => import('app/reader/DecisionReviewer'));

const ReaderRoutes = (props) => {
  return (
    <Loadable>
      <Route path="/:vacolsId/documents" render={() => <DecisionReviewer {...props} />} />
    </Loadable>
  );
};

export default ReaderRoutes;

