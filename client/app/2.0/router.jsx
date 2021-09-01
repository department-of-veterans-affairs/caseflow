// External Dependencies
import React from 'react';

// Lazy Load Routes
import ReaderRoutes from 'routes/Reader';

const Router = (props) => {
  return (
    <React.Fragment>
      <ReaderRoutes {...props} />
    </React.Fragment>
  );
};

export default Router;
