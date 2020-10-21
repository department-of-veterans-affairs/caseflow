// External Dependencies
import React from 'react';
import { Switch } from 'react-router-dom';

// Lazy Load Routes
const ReaderRoutes = React.lazy(() => import('app/2.0/routes/Reader'));

const Router = (props) => {
  return (
    <Switch>
      <ReaderRoutes {...props} />
    </Switch>
  );
};

export default Router;
