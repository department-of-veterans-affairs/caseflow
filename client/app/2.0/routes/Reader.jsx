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
      <div />
    </Loadable>
  );
};

export default ReaderRoutes;

