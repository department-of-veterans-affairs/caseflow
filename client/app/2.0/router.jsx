// External Dependencies
import React from 'react';

// Lazy Load Routes
const ReaderRoutes = React.lazy(() => import('app/2.0/routes/Reader'));

const Router = (props) => {
  return (
    <React.Fragment>
      <ReaderRoutes {...props} />
    </React.Fragment>
  );
};

export default Router;
